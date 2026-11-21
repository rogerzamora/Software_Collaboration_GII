# Software Collaboration and GitHub Commits - Blog # 3

## Summary
This work built the data behind the Global Innovation Index (GII) indicator on GitHub commits per million population, and the blog post that presents it. The post, "Software Collaboration Hits 5 Billion GitHub Commits", was published on 30 April 2026 in the GII Innovation Insights blog, co-authored with Kevin Xu (GitHub), Davide Bonaglia and Lorena Rivera León. It shows that commits on public GitHub repositories rose from about 1.7 billion in 2019 to close to 5 billion in 2025, an average growth of close to 19% a year.

I wrote the R workflow that turns GitHub's raw data into a clean, comparable indicator for every economy. It reads the data from cloud storage, standardizes country codes, reshapes the years, scales by working-age population and writes the result into the GII database. The whole workflow is documented in R Markdown, so every step can be read, rerun and checked.

## Background
Software is one of the fastest-growing forms of innovation, but it rarely shows up in traditional statistics. Patents and R&D spending miss much of it, because most software is written and shared openly rather than registered. GitHub is the world's largest platform for this work, and every saved change to a project, called a commit, leaves a trace. Counted across economies, commits give a timely view of where software is being built.
The challenge is turning a private company's raw records into an official indicator. The data arrives in GitHub's own format, with country codes, years and totals that do not match the GII database. It must be cleaned, made comparable across economies of very different sizes, and checked against strict database rules before it can enter the index. I designed the workflow to do this the same way every year.

## Data sources
The indicator combines three sources. The main one is GitHub itself. Through a collaboration between the GII team and GitHub, Kevin Xu at GitHub sends yearly totals of commits sent and received by public repositories in each economy. Automated bot activity is removed before counting, so the data reflects work done by people. The files are stored in the GII team's cloud storage on Box.
To compare economies of very different sizes, commits are divided by the working-age population (ages 15–69) from the United Nations World Population Prospects 2024. This age group approximates the pool of people who could be active developers. The population figures are held in the GII database, which also provides the official list of economies covered by the index. China is excluded because GitHub access there is unavailable or unreliable, and developers use local platforms instead. Hong Kong, China is also excluded.

## Intended audience
The blog is written for WIPO's member states, including ministries, national statistical offices and innovation agencies, as well as the technology industry, researchers and journalists. They want to know where software is being created, how fast it is growing and how their economy compares with others.

## Methodology
The work followed seven steps, all built in R. Each step produces an output the next one builds on, and the whole sequence can be rerun when GitHub sends a new year of data.
- I built the workflow as an R Markdown workbook that produces both an HTML and a PDF report, so the code, its explanations and its results sit in one document. The first lines set the three parameters that change between editions: the GII year (2026), the indicator code and the population measure used for scaling.
- The workbook connects to the GII database, hosted on Amazon Web Services, through the team's internal R package, and to Box through its API. Credentials are kept in configuration files outside the code. It then reads the indicator's metadata from the database, so names and codes always match the official records.
- Three inputs are loaded: GitHub's raw file, read directly from Box; the working-age population figures, filtered to the right GII year and source and converted to millions; and the list of GII economies, pulled with an SQL query.
- GitHub identifies economies with two-letter codes, while the GII uses three-letter codes. Namibia's code, "NA", is read by R as a missing value, so I corrected it first. The countrycode package then converts every two-letter code into its three-letter equivalent.
- The raw file has one column per year. Using tidyr's pivot_longer with a pattern that extracts the year from each column name, I turned it into one row per economy and year, and removed empty values.
- Joining with the population data, I divided each economy's commits by its working-age population in millions, which gives commits per million working-age population. A second join keeps only the economies covered by the GII, and China and Hong Kong, China are removed.
- The final data frame matches the seven columns of the GII's indicator table, each with a strict format: report year, indicator code, three-letter economy code, data year, raw value, scaled value and scaling factor. The data is then written into the database, which rejects any record that breaks these rules, and the connection is closed.

This order puts judgment where it matters most: matching economies correctly, choosing the right population measure and checking every record. The repetitive parts, reading, reshaping and loading the data, are automated, so each new edition takes little more than a new file and a new GII year.

## Outputs
The work produced three concrete answers:
- How fast is software collaboration growing? Commits nearly tripled, from about 1.7 billion in 2019 to close to 5 billion in 2025, with growth of close to 19% a year and no break after the pandemic. Growth sped up again in 2024–2025, which the authors link to generative AI coding assistants, cloud-native development and open-source AI models.
- Where is software being built? The United States leads with over 1.06 billion commits, followed by India with close to 446 million, and the top 15 economies account for about two-thirds of all activity. The share of Europe and Northern America fell from close to 80% in 2019 to closer to 60% in 2025, while India's share more than doubled, from 3.9% to 9.4%.
- Which economies are most active relative to their size? Once scaled by working-age population, Singapore leads with close to 20 million commits per million inhabitants, about two and a half times the next economy, followed by the Netherlands, Switzerland and Finland.

All figures come from the same cleaned dataset in the GII database, so the blog, the index and the charts show the same numbers.

## Relevance to the creative economy
Software is one of the core copyright industries: code is protected by copyright, and software and databases are counted as measured intangible investment in the national accounts. Open-source collaboration on GitHub is creative work in digital form, made by people and shared across borders.
The workflow is also a template for the alternative data the CEDM would need. Streaming services, music platforms and other digital content companies hold records of creative activity much like GitHub's commits. The same steps apply: receive data from a private partner, standardize economies and years, scale by population, check it against strict rules and load it into an official database.

## Impact
The work shows that private platform data can become a trusted official indicator. Its impact falls in five areas.
- It brought a timely measure of software creation into the GII, built on a direct partnership with a private company.
- It showed that software collaboration has nearly tripled since 2019, with growth shifting toward Asia, Africa and Latin America.
- Scaling by working-age population lets small economies such as Singapore be compared fairly with large ones such as the United States.
- No record enters the GII unless it passes the database's format and consistency checks.
- The workflow is documented and reusable: each year, only the GII year and the new file change.

## Conclusion
This work shows that I can take raw data from a private platform, turn it into an official indicator and connect it to a public story that policymakers read. The same logic applies to the CEDM. Creative activity increasingly happens on digital platforms, and measuring it means building data partnerships with external institutions such as GitHub, cleaning and scaling the data in a reproducible way, and making it comparable across economies before aggregating to the global level.

