# Tests of the processing scripts on synthetic data.

person_days <- function() {
  run_script("process_person_days.R",
             transplant_data_unprocessed = synthetic_subjects,
             InterventionDate = synthetic_day_0)$transplant_data_processed
}

offers <- function(subjects = synthetic_subjects, offers = synthetic_offers,
                   corrections = synthetic_corrections) {
  run_script("process_offers.R",
             organ_offers_unprocessed = offers,
             transplant_data_unprocessed = subjects,
             InterventionDate = synthetic_day_0,
             HIV_reason_list = synthetic_hiv_reasons,
             record_corrections = corrections)$organ_offers_processed
}

# Person-days ---------------------------------------------------------------

test_that("each candidate has one row per day of follow-up", {
  days <- person_days()
  per_candidate <- count(ungroup(days), Study_ID)
  expect_equal(per_candidate$n[per_candidate$Study_ID == "S01"], 40)
  expect_equal(per_candidate$n[per_candidate$Study_ID == "S02"], 47)
  expect_equal(per_candidate$n[per_candidate$Study_ID == "S03"], 42)
  expect_equal(nrow(days), 40 + 47 + 42)
})

test_that("a candidate with less than a day of follow-up stops the run", {
  # With such a candidate, R would measure every follow-up length in seconds,
  # and the original code would expand every candidate into seconds.
  zero <- bind_rows(synthetic_subjects,
                    tibble(Study_ID = "S04", Candidate_Last_Name = "Delta",
                           Date_of_consent = utc("2021-03-10"), End_Date = utc("2021-03-10"),
                           Date_of_TXP = utc(NA), Transplanted = 0, HIV_transplanted = 0,
                           Listing_Status = "Active"))
  expect_error(run_script("process_person_days.R",
                          transplant_data_unprocessed = zero,
                          InterventionDate = synthetic_day_0),
               "not days")
})

test_that("a day is post-intervention only if it starts after day 0", {
  days <- person_days()
  boundary <- filter(days, Study_ID == "S01")
  starts_on_day_0 <- boundary$start_date == as.POSIXct(synthetic_day_0, tz = "UTC")
  expect_equal(sum(starts_on_day_0), 1)
  expect_false(boundary$Post_Intervention[starts_on_day_0])
  expect_true(boundary$Post_Intervention[which(starts_on_day_0) + 1])
  expect_false(boundary$Post_Intervention[which(starts_on_day_0) - 1])
  # Every day of a candidate consented after day 0 is post-intervention
  expect_true(all(filter(days, Study_ID == "S03")$Post_Intervention))
})

test_that("each transplant is counted once, on the day ending on the transplant date", {
  days <- person_days()
  totals <- ungroup(days) %>%
    group_by(Study_ID) %>%
    summarise(all = sum(Transplant_Outcome), hiv = sum(HIV_Transplant_Outcome),
              last_day_ends_on_txp = any(Is_Transplant_date & stop_date == Date_of_TXP))
  expect_equal(totals$all, c(1, 0, 1))
  expect_equal(totals$hiv, c(1, 0, 0))
  expect_equal(totals$last_day_ends_on_txp, c(TRUE, FALSE, TRUE))
})

test_that("date-times compare correctly with day 0 when lubridate is attached", {
  # Base R alone compares a date-time with a date incorrectly; the scripts
  # rely on lubridate being attached, as setup.R does.
  expect_false(as.POSIXct("2021-03-10", tz = "UTC") > synthetic_day_0)
  expect_true(as.POSIXct("2021-03-16", tz = "UTC") > synthetic_day_0)
})

# Offers --------------------------------------------------------------------

test_that("duplicate offers of one donor to one candidate are removed", {
  processed <- offers()
  expect_equal(nrow(processed), 4)
  expect_equal(sum(processed$Donor_ID == "X1"), 1)
})

test_that("offers are assigned to periods, flagged and corrected as the plan says", {
  processed <- offers()
  by_donor <- split(processed, processed$Donor_ID)
  expect_false(by_donor$X1$Post_Intervention)            # before day 0
  expect_false(by_donor$X3$Post_Intervention)            # on day 0
  expect_true(by_donor$X2$Post_Intervention)             # after day 0
  expect_true(by_donor$X1$Potential_HIV_Donor_decline)   # listed refusal code
  expect_false(by_donor$X2$Potential_HIV_Donor_decline)  # other refusal code
  expect_true(is.na(by_donor$X3$Potential_HIV_Donor_decline))  # not declined
  expect_false(by_donor$X3$organ_was_transplanted)       # missing count
  expect_equal(by_donor$X4$Offer_Acceptance, "Provisional Acceptance")
})

test_that("offers get study IDs and lose candidate names", {
  processed <- offers()
  expect_equal(processed$Study_ID[processed$Donor_ID == "X4"], "S03")
  expect_false("Candidate_Last_Name" %in% names(processed))
})

test_that("the link stops if two candidates share a last name", {
  shared <- mutate(synthetic_subjects, Candidate_Last_Name = replace(Candidate_Last_Name, 2, "Alpha"))
  expect_error(offers(subjects = shared), "share a last name")
})

test_that("the link stops if the offers already have a Study_ID column", {
  expect_error(offers(offers = mutate(synthetic_offers, Study_ID = "S01")), "already has a Study_ID")
})
