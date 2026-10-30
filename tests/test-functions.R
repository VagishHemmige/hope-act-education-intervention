# Tests of R/functions.R on synthetic data.

test_that("apply_record_corrections changes only the named record", {
  corrected <- apply_record_corrections(synthetic_offers, synthetic_corrections,
                                        "organ_offers", "Match_ID")
  changed <- corrected$Offer_Acceptance != synthetic_offers$Offer_Acceptance
  expect_equal(sum(changed, na.rm = TRUE), 1)
  expect_equal(corrected$Offer_Acceptance[corrected$Match_ID == 9005], "Provisional Acceptance")
})

test_that("apply_record_corrections ignores corrections for other sources", {
  other <- mutate(synthetic_corrections, source = "subjects")
  expect_identical(
    apply_record_corrections(synthetic_offers, other, "organ_offers", "Match_ID"),
    synthetic_offers
  )
})

test_that("apply_record_corrections stops when a correction matches no record", {
  wrong <- mutate(synthetic_corrections, record_id = "1")
  expect_error(apply_record_corrections(synthetic_offers, wrong, "organ_offers", "Match_ID"),
               "matches 0 records")
})

test_that("apply_record_corrections stops when a correction matches two records", {
  twice <- bind_rows(synthetic_offers, filter(synthetic_offers, Match_ID == 9005))
  expect_error(apply_record_corrections(twice, synthetic_corrections, "organ_offers", "Match_ID"),
               "matches 2 records")
})

test_that("apply_record_corrections stops on a missing identifier or an unknown field", {
  missing_id <- mutate(synthetic_offers, Match_ID = replace(Match_ID, 1, NA))
  expect_error(apply_record_corrections(missing_id, synthetic_corrections, "organ_offers", "Match_ID"),
               "have no Match_ID")
  unknown <- mutate(synthetic_corrections, field = "Not_A_Field")
  expect_error(apply_record_corrections(synthetic_offers, unknown, "organ_offers", "Match_ID"),
               "does not exist")
})

test_that("apply_record_corrections never names the record in its messages", {
  wrong <- mutate(synthetic_corrections, record_id = "424242")
  message <- tryCatch(
    apply_record_corrections(synthetic_offers, wrong, "organ_offers", "Match_ID"),
    error = conditionMessage
  )
  expect_false(grepl("424242", message))
})

test_that("jitter_days shifts by at most max_days, keeps NA, and repeats with the seed", {
  x <- c(seq(-500, 500, by = 10), NA)
  shifted <- jitter_days(x, 2, seed = 123)
  expect_true(all(abs(shifted - x) <= 2, na.rm = TRUE))
  expect_true(is.na(shifted[length(shifted)]))
  expect_identical(shifted, jitter_days(x, 2, seed = 123))
  expect_false(identical(shifted, jitter_days(x, 2, seed = 124)))
  expect_true(any(shifted != x, na.rm = TRUE))
  expect_true(all(shifted == round(shifted), na.rm = TRUE))
})

test_that("jitter_days does not change the session's random numbers", {
  set.seed(1)
  expected <- runif(3)
  set.seed(1)
  jitter_days(1:10, 2, seed = 99)
  expect_identical(runif(3), expected)
})

test_that("the checks stop with the names of what is missing", {
  expect_error(check_files_exist("no-such-file.csv"), "no-such-file.csv")
  expect_error(check_names_present(c("a", "b"), c("a", "c"), "test"), "lacks: c")
  expect_error(check_rows_unchanged(3, 4, "A step"), "3 to 4")
})

test_that("jitter_days never moves a value to the other side of day 0", {
  x <- rep(c(-3:3, NA), times = 200)
  shifted <- jitter_days(x, 2, seed = 7)
  kept <- !is.na(x)
  expect_true(all((x[kept] <= 0) == (shifted[kept] <= 0)))
  expect_true(all(abs(shifted[kept] - x[kept]) <= 2))
  # Values near day 0 still move
  expect_true(any(shifted[kept & abs(x) <= 1] != x[kept & abs(x) <= 1]))
})

test_that("jitter_days never moves a value from before day 0 onto day 0", {
  x <- rep(c(-2, -1, 0, NA), times = 500)
  shifted <- jitter_days(x, 2, seed = 7)
  before <- !is.na(x) & x < 0
  expect_true(all(shifted[before] < 0))
  expect_true(all(abs(shifted[before] - x[before]) <= 2))
  # Values exactly on day 0 still stay at or before it, as before.
  on_day_0 <- !is.na(x) & x == 0
  expect_true(all(shifted[on_day_0] <= 0))
})

test_that("relabel_levels renames levels without changing their order or the values", {
  x <- c("Donor age", "Donor age or quality", NA, "Not Reported", "Donor age or quality")
  shown <- relabel_levels(x, c("Donor age or quality" = "Donor quality", "Absent" = "Ignored"))
  expect_equal(levels(shown), c("Donor age", "Donor quality", "Not Reported"))
  expect_equal(as.integer(shown), as.integer(factor(x)))
  expect_true(is.na(shown[3]))
  period <- relabel_levels(c(TRUE, FALSE, TRUE), c("FALSE" = "Pre", "TRUE" = "Post"))
  expect_equal(as.character(period), c("Post", "Pre", "Post"))
  expect_equal(levels(period), c("Pre", "Post"))
})
