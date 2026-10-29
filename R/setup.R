# Purpose: attach packages, define file locations and shared constants, and read
#   the restricted values that were removed from the code for patient privacy.
# Needs: nothing.
# Produces: attached packages; path constants; HIV_reason_list;
#   timeline_jitter_days; InterventionDate; timeline_jitter_seed;
#   record_corrections.
# Object names follow the original R Markdown file, so each step can be
# compared with original/original-analysis-2025-01-14.Rmd.

## ---- load-packages
library(tidyverse)
library(readxl)
library(lubridate)   # also needed so date-times compare correctly with dates
library(gtsummary)
library(gt)
library(janitor)
library(strex)
library(plotly)
library(yaml)

## ---- define-paths
data_dir <- "data-raw"
offers_file <- file.path(data_dir, "organ-offers-clean.xls")
subjects_file <- file.path(data_dir, "subjects-clean-2022-05-04.xlsx")
demographics_file <- file.path(data_dir, "demographics-2023-09-18.xlsx")
restricted_parameters_file <- file.path(data_dir, "restricted-parameters.yml")
record_corrections_file <- file.path(data_dir, "record-corrections.csv")
tables_dir <- "tables"
figures_dir <- "figures"

## ---- define-study-constants
# OPTN refusal codes counted as a potentially HIV-related decline, exactly as
# they appear in the data (analysis-plan.md section 7). The paper calls the
# first one "Donor quality".
HIV_reason_list <- c(
  "Donor age or quality",
  "Donor medical history, specify",
  "Donor social history",
  "Positive infectious disease screening test: CMV, HBV, HCV, etc."
)

# Patient timeline: each plotted event is moved by its own random shift of up
# to this many days, the precision of the published static figure
# (analysis-plan.md section 10).
timeline_jitter_days <- 2

## ---- read-restricted-parameters
# The intervention date (day 0) and the timeline's random seed are kept in the
# restricted folder, not in the code: with exact day offsets, the intervention
# date would give each candidate's event dates, and a public seed would let the
# timeline's shifts be regenerated and removed. Their values are never printed.
check_files_exist(c(restricted_parameters_file, record_corrections_file))

restricted_parameters <- read_yaml(restricted_parameters_file)
check_names_present(
  names(restricted_parameters),
  c("intervention_date", "timeline_jitter_seed"),
  restricted_parameters_file
)
InterventionDate <- ymd(restricted_parameters$intervention_date, quiet = TRUE)
if (is.na(InterventionDate)) {
  stop("intervention_date in ", restricted_parameters_file,
       " is not a date written as YYYY-MM-DD.", call. = FALSE)
}
timeline_jitter_seed <- as.integer(restricted_parameters$timeline_jitter_seed)
if (is.na(timeline_jitter_seed)) {
  stop("timeline_jitter_seed in ", restricted_parameters_file,
       " is not a whole number.", call. = FALSE)
}
rm(restricted_parameters)

# Record-level corrections: one row per corrected value, with the reason.
record_corrections <- read_csv(
  record_corrections_file,
  col_types = cols(.default = col_character())
)
check_names_present(
  names(record_corrections),
  c("source", "record_id", "field", "corrected_value", "reason"),
  record_corrections_file
)
