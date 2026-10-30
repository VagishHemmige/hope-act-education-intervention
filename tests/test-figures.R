# Tests of R/figures.R on synthetic data: the timeline is drawn from shifted
# days only, and every shift is within the limit.

timeline <- function(subjects = synthetic_subjects) {
  offers_env <- run_script("process_offers.R",
                           organ_offers_unprocessed = synthetic_offers,
                           transplant_data_unprocessed = synthetic_subjects,
                           InterventionDate = synthetic_day_0,
                           HIV_reason_list = synthetic_hiv_reasons,
                           record_corrections = synthetic_corrections)
  suppressPackageStartupMessages({library(ggplot2); library(plotly)})
  run_script("figures.R",
             transplant_data_unprocessed = subjects,
             organ_offers_processed = offers_env$organ_offers_processed,
             InterventionDate = synthetic_day_0,
             timeline_jitter_days = 2,
             timeline_jitter_seed = 20211L,
             figures_dir = withr::local_tempdir(.local_envir = parent.frame()))
}

exact_days <- function(dates) as.numeric(as.Date(dates) - synthetic_day_0)

test_that("every plotted day is within two days of the exact day", {
  env <- timeline()
  follow_up <- env$timeline_follow_up
  expect_true(all(abs(follow_up$consent_day - exact_days(synthetic_subjects$Date_of_consent)) <= 2))
  expect_true(all(abs(follow_up$end_day - exact_days(synthetic_subjects$End_Date)) <= 2))
  offer_points <- filter(env$graphic_data_points, str_detect(Event, "^HIV offer"))
  exact_offers <- exact_days(mdy(arrange(distinct(synthetic_offers, PX_ID, Donor_ID, .keep_all = TRUE), Donor_ID)$Match_Date))
  expect_true(all(abs(offer_points$endpoint - exact_offers) <= 2))
})

test_that("no plotted event changes side of day 0", {
  env <- timeline()
  follow_up <- env$timeline_follow_up
  exact_consent <- exact_days(synthetic_subjects$Date_of_consent)
  exact_end <- exact_days(synthetic_subjects$End_Date)
  expect_true(all((follow_up$consent_day <= 0) == (exact_consent <= 0)))
  expect_true(all((follow_up$end_day <= 0) == (exact_end <= 0)))
})

test_that("the end-of-follow-up point and the end of the line share one shift", {
  env <- timeline()
  ends <- filter(env$graphic_data_points, !str_detect(Event, "^HIV offer"))
  lines <- env$graphic_data_lines
  line_end <- coalesce(lines$endpoint2_right, lines$endpoint1_right)
  matched <- inner_join(ends, tibble(Study_ID = lines$Study_ID, line_end), by = "Study_ID")
  expect_equal(matched$endpoint, matched$line_end)
})

test_that("every candidate keeps a line when consent or end is just before day 0", {
  # SYNTHETIC: 40 extra candidates, none transplanted. Half consent one or two
  # days before day 0; half end follow-up one or two days before it.
  near_day_0 <- tibble(
    Study_ID            = sprintf("N%02d", 1:40),
    Candidate_Last_Name = sprintf("Near%02d", 1:40),
    Date_of_consent     = utc(as.character(synthetic_day_0 - c(rep(1:2, 10), rep(30, 20)))),
    End_Date            = utc(as.character(synthetic_day_0 + c(rep(10, 20), -rep(1:2, 10)))),
    Date_of_TXP         = utc(NA),
    Transplanted        = 0,
    HIV_transplanted    = 0,
    Listing_Status      = "Deceased"
  )
  lines <- timeline(subjects = bind_rows(synthetic_subjects, near_day_0))$graphic_data_lines
  has_segment <- (!is.na(lines$endpoint1_left) & !is.na(lines$endpoint1_right)) |
    (!is.na(lines$endpoint2_left) & !is.na(lines$endpoint2_right))
  expect_true(all(has_segment))
})

test_that("the timeline is saved as an image and an interactive page", {
  env <- timeline()
  expect_true(file.exists(file.path(env$figures_dir, "timeline.png")))
  expect_true(file.exists(file.path(env$figures_dir, "timeline.html")))
})
