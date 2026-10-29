# Purpose: expand each candidate's follow-up into one row per day, assign each
#   day to the pre- or post-intervention period, and mark the transplant day.
# Needs: setup.R (InterventionDate) and load_data.R
#   (transplant_data_unprocessed).
# Produces: transplant_data_processed, one row per candidate-day.
# As in the original code (analysis-plan.md sections 5 and 7).

## ---- expand-person-days
# Each candidate contributes one row per day from consent to the end of
# follow-up. Day k starts k - 1 days after consent and ends k days after.
# The original code's duration is End_Date - Date_of_consent, whose units R
# chooses from the smallest difference in the column: days when every
# candidate has at least a day of follow-up, but seconds if any candidate has
# none, which would expand every candidate into seconds. Stop rather than
# reproduce that; the published analysis must have had days.
follow_up_length <- transplant_data_unprocessed$End_Date - transplant_data_unprocessed$Date_of_consent
if (units(follow_up_length) != "days") {
  stop("Follow-up lengths are in ", units(follow_up_length),
       ", not days, because a candidate has less than a day of follow-up. ",
       "The original code would expand follow-up incorrectly.", call. = FALSE)
}
rm(follow_up_length)

transplant_data_processed <- transplant_data_unprocessed %>%
  mutate(duration = as.numeric(End_Date - Date_of_consent)) %>%
  uncount(duration) %>%
  group_by(Study_ID) %>%
  mutate(start_date = days(row_number()) + Date_of_consent - days(1),
         stop_date = days(row_number()) + Date_of_consent)

## ---- assign-period-to-days
# A day is post-intervention when it starts after day 0.
transplant_data_processed <- transplant_data_processed %>%
  mutate(Post_Intervention = start_date > InterventionDate)

## ---- mark-transplant-day
# A transplant counts on the day that ends on the transplant date; every other
# day counts 0. The D+/R+ outcome counts only transplants from donors with HIV.
transplant_data_processed <- transplant_data_processed %>%
  mutate(Is_Transplant_date = (Date_of_TXP == stop_date)) %>%
  mutate(Is_Transplant_date = if_else(is.na(Is_Transplant_date), FALSE, Is_Transplant_date)) %>%
  mutate(Transplant_Outcome = ifelse(Is_Transplant_date, Transplanted, 0)) %>%
  mutate(HIV_Transplant_Outcome = ifelse(Is_Transplant_date, HIV_transplanted, 0))

## ---- check-person-days
# Every candidate's days are present, and a candidate's transplant is counted
# at most once.
expected_days <- transplant_data_unprocessed %>%
  mutate(duration = as.numeric(End_Date - Date_of_consent)) %>%
  pull(duration) %>%
  sum()
check_rows_unchanged(expected_days, nrow(transplant_data_processed),
                     "Expanding follow-up into days")

transplants_counted_twice <- transplant_data_processed %>%
  summarise(transplant_days = sum(Is_Transplant_date)) %>%
  filter(transplant_days > 1)
if (nrow(transplants_counted_twice) > 0) {
  stop("A candidate has more than one transplant day.", call. = FALSE)
}
rm(expected_days, transplants_counted_twice)
