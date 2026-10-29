# Architecture

How the code is organized now. `REPOSITORY-BLUEPRINT.md` describes the intended layout, `analysis-plan.md` what the analysis must do, and `AGENTS.md` the working rules.

## Running

`R/main.R`, run from the project root in a fresh session, sources the scripts below in this order. Each script's header says what it needs and produces. The restricted files it reads are listed in `README.md` and are never in the repository.

| Order | Script | Does | Produces |
|---|---|---|---|
| 1 | `R/functions.R` | Helper functions: file and column checks, record corrections, day jitter, saving tables | Functions |
| 2 | `R/setup.R` | Attaches packages, defines paths and constants, reads the restricted values | `HIV_reason_list`, `timeline_jitter_days`, `InterventionDate`, `timeline_jitter_seed`, `record_corrections` |
| 3 | `R/load_data.R` | Reads the three study files and checks their columns | `organ_offers_unprocessed`, `transplant_data_unprocessed`, `Demographics_unprocessed` |
| 4 | `R/process_person_days.R` | Expands follow-up into candidate-days, assigns periods, marks transplant days | `transplant_data_processed` |
| 5 | `R/process_offers.R` | Offer dates, duplicate removal, periods, derived measures, study ID link, corrections | `organ_offers_processed` |
| 6 | `R/process_demographics.R` | Derived candidate, donor and transplant characteristics | `Demographics` |
| 7 | `R/models.R` | Poisson models of transplant rate | `m1`, `m2` |
| 8 | `R/tables.R` | Table 2, declined-offer tables, model tables, Supplemental Tables 1 and 2 | Tables in `tables/` |
| 9 | `R/figures.R` | Patient timeline with each event shifted by up to two days | `figures/timeline.png`, `figures/timeline.html` |

`functions.R` comes before `setup.R` because `setup.R` uses its checks when reading the restricted values.

## Data flow

```text
data-raw/ (restricted)
  ├── restricted-parameters.yml ─┐
  ├── record-corrections.csv ────┴─ setup.R ── InterventionDate, timeline_jitter_seed, record_corrections
  ├── subjects ──────── load_data.R ── transplant_data_unprocessed ─┬─ process_person_days.R ── models.R ── tables.R
  │                                                                 ├─ process_offers.R (study ID link) ─┬─ tables.R
  ├── organ offers ──── load_data.R ── organ_offers_unprocessed ────┘                                    └─ figures.R
  └── demographics ──── load_data.R ── Demographics_unprocessed ── process_demographics.R ── tables.R
```

Object names follow the original R Markdown file (`original/original-analysis-2025-01-14.Rmd`), so each step can be compared with it.

## Tests

`tests/` holds tests on synthetic data, built by hand in `tests/helper-synthetic.R` and never derived from real records. Run them with `testthat::test_dir("tests")`. They cover the helper functions, the person-day expansion and period boundary, the offer processing, link and correction, and the timeline's shifts. The table scripts and the demographics processing are not yet tested.
