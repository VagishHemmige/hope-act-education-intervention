# R Analysis Repository Blueprint

Intended file organization for this analysis. `ARCHITECTURE.md` describes the current implementation.

```text
repository/
├── R/
│   ├── main.R               # Orchestrates the definitive analysis
│   ├── functions.R          # Reusable functions (sourced first)
│   ├── setup.R              # Packages, paths, shared constants, restricted values
│   ├── load_data.R          # Reads the restricted study files
│   ├── process_*.R          # Offers, person-days, demographics
│   ├── models.R             # Poisson models
│   ├── tables.R             # Generates the tables
│   └── figures.R            # Generates the figures
├── tests/                   # Tests on synthetic data
├── original/                # The original R Markdown file, restricted values removed
├── figures/                 # Generated figures (ignored until cleared)
├── tables/                  # Generated tables (ignored until cleared)
├── references/              # Supporting literature and evidence
├── quarto/                  # Explanatory Quarto pages
├── _extensions/             # Quarto extensions, when used
├── docs/                    # Rendered website, served by GitHub Pages
├── _quarto.yml              # Quarto configuration
├── index.qmd                # Website entry point
├── README.Rmd               # Source for README.md
├── README.md                # Overview and execution
├── analysis-plan.md         # Scientific objectives and methods
├── references.bib           # Bibliographic citations
├── AGENTS.md                # Rules for people and agents
├── ARCHITECTURE.md          # Current implementation
├── REPOSITORY-BLUEPRINT.md  # Intended organization
├── hope-act-education-intervention.Rproj  # RStudio project file (not used by Positron)
└── .gitignore               # Project-specific exclusions
```

Two folders exist only on the maintainer's computer and are never committed:

```text
├── data-raw/                # Restricted study files and restricted values
└── Archive/                 # Earlier code versions, outputs and manuscript drafts
```

## Analytical scripts

- `R/main.R` sources the definitive scripts in dependency order.
- Workflow: functions and setup → loading → processing (offers, person-days, demographics) → models → tables and figures.
- `R/tables.R` and `R/figures.R` generate the outputs directly.

## Documentation

- Document definitive analytical scripts with explanatory Quarto pages; exploratory scripts need not have pages.
- Use [Dialysis-facility-density-USRDS](https://github.com/VagishHemmige/Dialysis-facility-density-USRDS) as the example for a site that documents a published analysis, and [Cryptococcus-cost-analysis](https://github.com/VagishHemmige/Cryptococcus-cost-analysis) for Quarto supporting files, chunk imports, callouts and formatting; neither for scientific methods.

## Outputs and version control

- Outputs from the restricted data stay local and out of Git until the decider has checked them against the paper and cleared them for release (`AGENTS.md`).
- **`.gitignore`:** excludes `data-raw/`, `Archive/`, any copy of the original code that still holds the restricted values, data formats, Stata logs, Word, PDF and HTML files outside `docs/`, `figures/`, `tables/`, credentials and caches. Ignoring a folder does not stop anyone, or any connected tool, from reading it.
