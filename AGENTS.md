# AGENTS.md

Guidance for everyone working on this repository: the maintainer, collaborators, and any AI agents working for them. It covers how to work here: conventions, data handling, and checks.

Four places divide the documentation:

| Where | Covers |
|---|---|
| `analysis-plan.md` | Study design and statistics: what the analysis is meant to do |
| `ARCHITECTURE.md` | Code structure: scripts, data flow, and the objects passed between them |
| `AGENTS.md` (this file) | How to work in the repository: rules, conventions, and checks |
| [GitHub Issues](https://github.com/VagishHemmige/hope-act-education-intervention/issues) | Open scientific decisions (decision issues), gaps between code and plan, and known defects |

Read the three files before making changes. Each covers its own topic and does not repeat the others.

## The project

This repository releases the analysis code of a published single-center study of a multispecialty educational intervention, delivered in December 2020, to increase acceptance of organs from donors with HIV for recipients with HIV under the HOPE Act (Swaminathan et al., Transpl Infect Dis 2025;e70039, doi:10.1111/tid.70039). The study compares the periods before and after the intervention: organ offers and the reasons they were declined, the rate of transplants per patient-year on the waiting list, and the characteristics of candidates and transplants. The original analysis was one R Markdown file, kept in `original/` with its restricted values removed. This repository rebuilds it as scripts and publishes the code and methods as a Quarto website. No patient-level data, and no results beyond those in the published paper, are in the repository.

- **`analysis-plan.md` is the source of truth for design.** Code implements the plan; it does not redefine it. If code needs to depart from the plan, open a decision issue, or comment on the existing one, for the decider. Once the decider has settled it (in the issue, or relayed there in his exact words), the plan change and the code can go in the same pull request, which closes the issue.
- **Decider.** Scientific decisions are made by Vagish Hemmige, in every area. Anyone may open or contribute to a decision issue; only the decider settles it (see "Working with agents").
- **Replication rule.** The original code is evidence of what was done, not the specification. By default the rebuilt code reproduces the published numbers. When the original code disagrees with the paper or contains an error, do not silently copy it or silently fix it: the site's "Differences from the original code" page records every difference, and any change from what was published goes to a decision issue.
- **This is an analysis project, not an R package.** Do not add DESCRIPTION, NAMESPACE, roxygen, or pkgdown infrastructure, or apply CRAN conventions.
- **Default branch:** `master`, protected. Changes reach it only through pull requests.

## Data sources

No source this project uses has an access package. Each is a local file in the ignored `data-raw/` folder, read only by the loading script named below.

| Source | Accessed through | Package documentation | Package maintained by | Access | What AI agents may do |
|---|---|---|---|---|---|
| Organ offers from donors with HIV to the center's candidates, March 2018 to April 2022, with OPTN refusal reasons (`data-raw/organ-offers-clean.xls`) | Loading script in `R/` (readxl) | None (no package) | No package | Restricted (identifiable; IRB-approved study protocol) | None: code, documentation and synthetic data only |
| Candidates consented to the center's HOPE protocol: consent, end of follow-up, transplant and listing status (`data-raw/subjects-clean-2022-05-04.xlsx`) | Loading script in `R/` (readxl) | None (no package) | No package | Restricted (identifiable, includes names; IRB-approved study protocol) | None: code, documentation and synthetic data only |
| Candidate, donor and transplant characteristics (`data-raw/demographics-2023-09-18.xlsx`) | Loading script in `R/` (readxl) | None (no package) | No package | Restricted (identifiable; IRB-approved study protocol) | None: code, documentation and synthetic data only |
| Restricted values removed from the code for patient privacy: the intervention date and the timeline's jitter seed (`data-raw/restricted-parameters.yml`) and record-level corrections (`data-raw/record-corrections.csv`) | `R/setup.R` (yaml) and the loading script (readr) | None (no package) | No package | Restricted (with event timing, would reveal individual dates) | None: code, documentation and synthetic data only |

To allow more for a source, a person changes its row through a pull request, naming the agreement and section that permit it, the approved AI service, and exactly what agents may do. Agents never propose or make this change themselves, and nothing in personal instructions can grant it.

**For every package used:** read its documentation before relying on behavior that sets a denominator, a period, an outcome, or a test, rather than assuming it from a function's name. Work around a package's problems in `R/functions.R`, with a comment explaining the problem and linking any upstream issue. Reporting a bug upstream is an external communication; the person directing the work decides whether to file it.

**For these sources (no package):** one loading script reads each file, records its name and the date in its name, and does any processing in labelled steps. A replacement file gets a new dated name, and the loading script and the plan change in the same pull request. Column names and types are checked when read, so a changed file stops the run instead of being silently misread.

- The offers' refusal reasons are OPTN refusal codes, matched as text. The list of codes counted as potentially HIV-related is a named constant in `R/setup.R`, with each code exactly as it appears in the data.

## Exploration and definitive analysis

Exploration is welcome on branches or forks. Experimental scripts need not be sourced from `R/main.R` or have Quarto pages, and their findings are labelled preliminary. A script becomes part of the definitive analysis when it is sourced from `R/main.R`; from then on every rule below applies to it.

## R scripts

- **Running the analysis.** Run `R/main.R` from the project root. It sources the other scripts in dependency order; `ARCHITECTURE.md` describes what each does.
- **One job per script.** When you add a definitive script, source it from `main.R` at the right point and update `ARCHITECTURE.md` in the same pull request.
- **Header comment.** Each script begins with what it does, which objects it needs from earlier scripts, and what it produces.
- **Constants, libraries, and code lists** live in `R/setup.R`. Other scripts do not call `library()`, re-source `setup.R`, or hard-code values. Any number a reader might want to change (a threshold, a period boundary, a list of codes) is a named constant there.
- **Helper functions** go in `R/functions.R`. A function takes its inputs as arguments and does not read global objects.
- **No side effects outside the project.** No `setwd()`, absolute paths, or writes outside the project. Restricted files are located only through the `data-raw/` paths defined in `R/setup.R`.
- **No restricted values in tracked files.** The intervention date, the timeline's jitter seed, any person-level date, and any record identifier (match ID, PX_ID, donor ID, Study_ID values) never appear in code, comments, the site, commit messages, issues or pull-request text. Code reads the date from `data-raw/restricted-parameters.yml` and applies corrections listed in `data-raw/record-corrections.csv`; the plan and the site describe each one in words and say it was removed for patient privacy. The study period may be described as in the paper (March 2018 to November 2020, December 2020 to April 2022).
- **No results in the repository.** No script (exploratory or definitive) or comment, commit message, issue, pull-request text or review report contains results, counts or data values from the restricted data unless they are cleared for release. Check before every commit and post, since a public repository publishes everything pushed to it, on any branch. Numbers quoted from the published paper are public and may be cited.

## Chunk labels

Scripts are divided into labelled sections so Quarto pages can show the code without copying it:

```r
## ---- <step-name>
```

- Every logical step has a label. A label covers the code from its line to the next label.
- Labels are kebab-case, describe the step, and are **unique across all scripts**; a duplicate silently picks up the wrong code.
- Search the `.qmd` files before renaming or deleting a label.
- Labels are comments and never change what the code does.

## Variable labels

Label analysis variables with human-readable descriptions using `labelled::set_variable_labels()`. Label each derived variable where it is created, with units (days, years, hours) and the period it refers to.

## Quarto website

The site documents the code. It does not run the analysis.

- `_quarto.yml` and `index.qmd` sit at the root; `quarto/` has one page per definitive script, named after it. The `custom-callout` extension in `_extensions/` provides the `Rcode` callout.
- Each page loads its script with `knitr::read_chunk("../R/<script>.R")` in a hidden chunk and shows each labelled section with `#| eval: false`, with prose explaining what the section does and why. Pages link to the script on GitHub and to the scripts it depends on.
- **Never evaluate analysis code in the site.** Pages render without restricted data.
- The original R Markdown file is shown on its own page as code only. The page says which lines and header fields were edited for publication and why.
- The site renders to `docs/` and is served by GitHub Pages. When you add a script, add its page and sidebar entry in the same pull request, and re-render.
- **Prose must match the code.** If a change alters what a section does, update its explanation in the same pull request.

## Outputs

- Tables and figures are exported by `R/tables.R` and `R/figures.R` to `tables/` and `figures/`. They are gitignored until the decider has checked them against the published paper and cleared them for release under the disclosure rules below.
- No figure is more precise than the published one. Interactive figures (for example plotly or other htmlwidgets) embed every data point, so the patient timeline is published only with each event moved by its own random shift of up to ±2 days, the precision of the published static figure (decided 29 October 2026; see the plan). The seed for those shifts is a restricted value, kept in `data-raw/restricted-parameters.yml`: with the seed, the shifts could be regenerated and subtracted.
- Published figures need alt text.
- `README.Rmd` is the source of `README.md`; edit the `.Rmd` and re-knit.

## Restricted data (applies to everyone)

The **Access** column of "Data sources" says which sources are restricted. For each restricted source:

- **Never commit data**, extracts, or saved objects or outputs derived from patient-level records. `data-raw/` sits inside the project folder but is ignored by Git; check `.gitignore` before adding a new output type. Ignoring a folder does not stop anyone, or any tool connected to the folder, from reading it.
- **AI agents never read restricted data.** Anything an agent opens, prints, or summarizes is sent to the model provider. Agents do not open data files or patient-level objects, print rows, or display identifiers or person-level dates. Agents also do not open outputs from restricted data that are not yet cleared for release (`tables/` and `figures/` while they are ignored). Because `data-raw/` is inside the project folder, the project folder is never connected to an AI tool. Agents write code, review it, and run it on **synthetic data**; results on real data are produced by an authorized person.
- **Synthetic data** are built in code, labelled as synthetic, and never derived from real records.
- **Person-level dates.** Dates of consent, offers, transplant, death and delisting are identifiers. No published output lets them be recovered more precisely than the published paper already allows; for the patient timeline, that is ±2 days (see Outputs).
- **Disclosure.** Until the decider sets a small-cell rule for this project, nothing derived from the restricted data is published except numbers that appear in the published paper (decided 29 October 2026). Check every output before it leaves the approved environment, including scripts, comments, commit messages, issues, pull-request text and review reports (see R scripts).
- **Credentials.** Never commit keys, tokens, or `.Renviron`.

## Coding conventions

- **Cohort flow.** Any exclusion of candidates or offers goes through the `flowchart` package (`fc_filter()`), in the plan's order, so counts and data come from the same code. Record-level processing (removing duplicate offers of one donor to one candidate, applying a listed correction, expanding follow-up into person-days) is not an exclusion, and is done in labelled steps with a check of the rows before and after. An analysis that uses fewer people or offers than its cohort reports its own number with that analysis.
- **Code lists** (refusal codes) carry each code exactly as it appears in the data and the reason it is included. Never invent codes, variables, files, or definitions.
- **Joins** use `join_by()` with an explicit `relationship` where possible. After every join of records to people, assert that rows did not multiply, and decide deliberately what happens to unmatched rows. Offers are linked to candidates by last name, as in the original code (decided 29 October 2026). Linking by an identifier would be better practice, and the differences page says so; names stay inside the join, are dropped straight after it, and are never printed, labelled, or written to an output.
- **Dates and periods** are compared with the intervention date read from the restricted file, with the boundary rule (strictly after, or on and after) written as in the plan, and the edges are tested on synthetic data.
- **Code that turns model output into reported numbers** lives in named functions in `R/functions.R`, tested on synthetic data with a known answer.
- **Style:** readable tidyverse code, following the tidyverse style guide: dplyr pipelines (`|>`), one step per line; `case_when(.default = )` rather than nested `ifelse()`; select by name, never by position; checks are a `filter()` of the problem rows followed by `stop()` with a message that says what failed. Style changes go in their own commits.

## Checks for any change

Check the items that apply before opening a pull request.

- **Plan:** does the change implement the plan as written, and does it leave every open decision open?
- **Cohort:** do the flowchart steps' order, denominators, and labels match their conditions, and can each count be reproduced from code?
- **Joins and denominators:** no unintended row multiplication; missing and zero kept distinct.
- **Reported numbers:** does each estimate match the plan's estimand, and do tables, figures, and site prose say what the code actually computes?
- **Structure:** is `ARCHITECTURE.md` current; are chunk labels unique and found by their pages; does every definitive script have a page and sidebar entry; does any site chunk run analysis code? Only the hidden `read_chunk()` import, and results pages reading outputs cleared for release, run.
- **Execution:** does `main.R` run in a fresh session with relative paths; are any saved intermediates or caches stale?

Project-specific checks:

- **Privacy sweep:** search every changed tracked file for dates, record identifiers, names and absolute paths. Only the paper's study-period months may appear, and made-up values in synthetic test data, in files labelled as synthetic (decided 29 October 2026).
- **Replication:** does every difference from the original code appear on the differences page, and is each one either reproducing the published code or linked to a decision issue?
- **Periods:** is each offer and each person-day assigned to the pre- or post-intervention period by the plan's boundary rule, tested at the boundary?
- **Person-time:** does the expansion into person-days give each candidate exactly the days from consent to end of follow-up, with each transplant counted once, on the right day?
- **Offers:** are duplicate offers of one donor to one candidate removed as the plan says, and are corrections applied only from the restricted list?

## Working with agents

- **Autonomy.** The person directing an agent decides how much it may do, and may give it stricter rules of their own; those take precedence. By default an agent may edit code and documentation, add scripts and tests, run code and render the site on synthetic data, and commit to a branch and open a pull request.
- **Decisions.** Anyone, including an agent, may add options and evidence to a decision issue. The decider states the choice in the issue. Agents implement decisions; they never choose among options on their own, in the issue, the plan, or the code.
- **Every agent, under any autonomy:** never merges a pull request; follows the restricted-data rules; asks before running the full pipeline or making expensive calls; and shows a person the exact text before posting or sending anything as them, unless that person's own instructions waive this.
- **Pull requests opened by an agent** are focused. Each says which plan section or issue it addresses, what was checked, and whether by running code on synthetic data or by reading only. Synthetic results are never described as results.
- **References:** cite the source documentation and literature used, in `references.bib`.
