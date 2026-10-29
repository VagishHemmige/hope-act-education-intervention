# Synthetic data for the tests. SYNTHETIC: invented by hand, not derived from
# any real record. The dates, IDs and names are made up, and day 0 here is an
# arbitrary date unrelated to the study's intervention date.
# testthat sources this file before the tests.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
  library(readr)
})

project_file <- function(...) testthat::test_path("..", ...)

source(project_file("R", "functions.R"))

synthetic_day_0 <- as.Date("2021-03-15")

utc <- function(x) as.POSIXct(x, tz = "UTC")

# Three candidates. Days of follow-up: A 40, B 47, C 42.
# A: consent before day 0, D+ transplant on the last day.
# B: consent before day 0, died, never transplanted.
# C: consent after day 0, D- transplant on the last day.
synthetic_subjects <- tibble(
  Study_ID            = c("S01", "S02", "S03"),
  Candidate_Last_Name = c("Alpha", "Bravo", "Charlie"),
  Date_of_consent     = utc(c("2021-03-01", "2021-02-01", "2021-03-20")),
  End_Date            = utc(c("2021-04-10", "2021-03-20", "2021-05-01")),
  Date_of_TXP         = utc(c("2021-04-10", NA, "2021-05-01")),
  Transplanted        = c(1, 0, 1),
  HIV_transplanted    = c(1, 0, 0),
  Listing_Status      = c("Transplanted", "Deceased", "Transplanted")
)

# Offers: X1 is offered twice to Alpha (a duplicate); X4 is the record the
# synthetic correction changes from Yes to Provisional Acceptance.
synthetic_offers <- tibble(
  PX_ID     = c(101, 101, 102, 101, 103),
  Donor_ID  = c("X1", "X1", "X2", "X3", "X4"),
  Match_ID  = c(9001, 9002, 9003, 9004, 9005),
  Match_Date = c("03/01/2021", "03/01/2021", "03/16/2021", "03/15/2021", "04/02/2021"),
  Candidate_Last_Name = c("Alpha", "Alpha", "Bravo", "Alpha", "Charlie"),
  HIV_Pos_to_Pos = "Yes",
  Offer_Acceptance = c("No", "No", "No", "Yes", "Yes"),
  Primary_Refusal_Reason = c("Donor age or quality", "Donor age or quality",
                             "Positive crossmatch", NA, NA),
  Number_of_Kidneys_tranplanted_from_Donor = c(2, 2, 0, NA, 1)
)

synthetic_corrections <- tibble(
  source = "organ_offers",
  record_id = "9005",
  field = "Offer_Acceptance",
  corrected_value = "Provisional Acceptance",
  reason = "Synthetic test correction"
)

synthetic_hiv_reasons <- c(
  "Donor age or quality",
  "Donor medical history, specify",
  "Donor social history",
  "Positive infectious disease screening test: CMV, HBV, HCV, etc."
)

# Run one analysis script in a fresh environment holding the given objects,
# and return that environment.
run_script <- function(script, ...) {
  env <- new.env(parent = environment(apply_record_corrections))
  objects <- list(...)
  for (name in names(objects)) assign(name, objects[[name]], envir = env)
  sys.source(project_file("R", script), envir = env)
  env
}
