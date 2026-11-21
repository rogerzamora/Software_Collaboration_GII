---
title:        "GII Data Collection & Cleaning"
subtitle:     "GHRecSentNoBot"
author:       "Roger Zamora"
date:         "`r format(Sys.time(), '%d %B %Y')`"
description:  "Cleaning and upload of the 7.3.3-GHRecSentNoBot indicator."
output:
  bookdown::html_document2:
    toc: yes
    toc_depth: 3
    toc_float: yes
    fig_caption: yes
    highlight: textmate
  bookdown::pdf_book:
    toc: yes
    toc_depth: 3
    fig_caption: yes
    highlight: haddock
header-includes:
  - \usepackage{colortbl}
  - \usepackage{float}
 ---
 
# Objective

This workbook collects and cleans data from GitHub.  It documents the cleaning process necessary to produce the pre-processed data for the "`r l.id$NAME_ABBR`" indicators.

The remainder of this workbook is organised as follows.  First, we load the raw data file received from Kevin to Box.  Next, we import all necessary data to perform the cleaning, which is followed by the cleaning process itself.  Finally, the cleaned data is exported to the `gii.indicator_prep` table.


# Collection

Data is received by emailing Kevin Xu <khxu@github.com> at GitHub. Data is stored in BOX: `GII_2025/Raw data/GitHub/`.

# Initial Setup
## Load libraries

```{r preamble, include=FALSE}

library(boxr)
library(dplyr) 
source(here::here("src/sql_tools.R"))
library(tidyr)

giiyr <- 2026
code <- "GHRecSentNoBot"
scaling_id <- "ACTPOP"
```

## Connect to AWS

```{r aws-connect, include=FALSE}
## Connect to AWS
## ... via config & RMariaDB
# db <- get_config("jg")
# con <- DBI::dbConnect(RMariaDB::MariaDB(),
#                       host = db$host,
#                       port = db$port,
#                       dbname = db$dbname,
#                       user = db$user,
#                       password = db$password)
# rm(db)

con <- giipack::connectMariaDB("js")
```

## Select Indicator

```{r id-tbl, echo=FALSE, results='hide'}
## SELECT INDICATOR -------------------------------------------------------------------------------

## This chunk will return the GII indicator code for the given GII year, indicator pillar id and status (usually we are interested in the "Active" indicator codes but you can adjust for "Inactive" as well). This produces a list object containing the selected indicator code and other metadata. 

l.id <- read_tbl(con, "id", giiyr, code) |> as.list()
```

## Connect to Box

```{r box, include=FALSE}
## BOX ----------------------000000000-----------------------------------------------------

## This chunk connects R to the Box API, permitting R to read and write directly to the cloud.
## The steps are as follows:
##  (1) Create a Box App which provides the necessary credentials. For instructions see:
##      <https://r-box.github.io/boxr/articles/boxr-app-interactive.html#:~:text=your%20local%20computer.-,Creating%20an%20Interactive%20App,-Keep%20in%20mind>.
##  (2) Enter the credentials into <config_box.yml> in the root folder of this repository.

## Connect to Box
l.box <- giipack::connectBox(giiyr)

## Get folder ID
l.box$folderID <- boxr::box_search(query = 'GitHub',
                        content_types = 'name',
                        type = 'folder',
                        ancestor_folder_ids = l.box$raw) %>% 
                  as.data.frame() %>% 
                  pull(id)

## Get file id

## Find IEA folder
# l.box$fileID <- boxr::box_search(query = 'GHRecSentNoBot',
#                               content_types = "tags",
#                               type = "file",
#                               ancestor_folder_ids = l.box$folderID) %>%
#                 base::as.data.frame() %>%
#                 dplyr::pull(id)

l.box$fileID <- 2140536160580
```


# Import

## Raw indicator data

```{r data-raw, message=TRUE}

## Read raw indicator data from Box
ind.raw <- boxr::box_read_csv(l.box$fileID)

ind.raw
```

## Scale factor data

```{r data-sf, message=TRUE}

sf.cln <- read_tbl(con, "scalers") %>% 
  
  ## Filter for the correct scaler
  dplyr::filter(GIIYR == giiyr & CODE == scaling_id & SOURCEID == "WPP24") %>% 
  dplyr::select(ISO3, DATAYR, SCALE_FACTOR = VALUE) %>% 
  dplyr::mutate(SCALE_FACTOR = SCALE_FACTOR / 10^3)

sf.cln
```

## Economy data

Finally, we import economy codes and names from the `gii.economy_id` table.

```{r data-econ-id}

## Read gii.economy_id table
# e <- read_tbl(con, "economy_id") %>% 
#   select(ISO3)
# 
# e

e <- DBI::dbGetQuery(con, glue::glue("
                             SELECT DISTINCT ISO3 
                             FROM gii.economy_id
                            "
                       ))
```

# Cleaning

This section describes and performs the cleaning process. We take the `df.qs_cur` data frame emailed to us by the developers. We aim for a dataframe with columns matching those in the `gii.indicator_prep` table:

- `GIIYR` $\longrightarrow$ GII report year as smallint(4) UNSIGNED NOT NULL
- `CODE` $\longrightarrow$ Indicator GII code as varchar(20) NOT NULL; immutable across indicators and report years
- `ISO3` $\longrightarrow$ Economy ISO3 code in format AAA as char(3) NOT NULL
- `DATAYR` $\longrightarrow$ GII data year as smallint(4) NOT NULL
- `VALUE_UNSCALED` $\longrightarrow$ Unscaled indicator value as double NULL
- `VALUE_SCALED` $\longrightarrow$ Scaled indicator value using SCALE_FACTOR as double NULL
- `SCALE_FACTOR` $\longrightarrow$ Indicator scaling factor as double NULL

```{r clean}

ind.cln <- ind.raw %>% 
  
           ## Correct Namibia and Kososvo ISO2
           dplyr::mutate(economy = case_when(is.na(economy) ~ "NA",
                                     TRUE ~ economy)) %>% 
  
           ## Add ISO3
           dplyr::mutate(ISO3 = countrycode::countrycode(economy, 
                                                        origin = 'iso2c', 
                                                        destination = 'iso3c')) %>% 

           ## Select the required columns
           dplyr::select(ISO3, starts_with("sum")) %>% 
        
           ## Transform to long format
           tidyr::pivot_longer(cols = starts_with("sum_sent_received"), 
                       names_to = "DATAYR", 
                       names_pattern = "sum_sent_received_(\\d{4})", 
                       values_to = "VALUE_UNSCALED") %>% 
           dplyr::mutate(DATAYR = as.integer(DATAYR)) %>% 
           tidyr::drop_na(VALUE_UNSCALED) %>% 
        
  
           ## Join with Scaling factor
           dplyr::inner_join(sf.cln, by = c("ISO3", "DATAYR")) %>% 
          
           ## Compute VALUE_SCALED
           dplyr::mutate(VALUE_SCALED = VALUE_UNSCALED / SCALE_FACTOR,
                         GIIYR = giiyr,
                         CODE = code) %>% 
          
           ## Join with df.econ
           dplyr::inner_join(e, by = "ISO3") %>% 
           
           dplyr::arrange(ISO3,DATAYR) %>% 
  
           ## Set CHN and HKG to NA
           dplyr::filter(!(ISO3 %in% c("CHN", "HKG")))
  

ind.cln
```

# Export

This section writes the cleaned indicator data and, if necessary, deletes removed data from the `gii.indicator_prep` table.  The database table contains strict data and format constraints, so if the writing fails please cross-check the produced error and your cleaned dataframe.

```{r export, message=TRUE}
## Insert cleaned data to gii.indicator_prep
insert(con, "indicator_prep", ind.cln)
```

# Disconnect AWS

```{r aws-disconnect, include=FALSE}
DBI::dbDisconnect(con)
```

