# Purpose: derive the candidate, donor and transplant characteristics used in
#   Supplemental Tables 1 and 2.
# Needs: setup.R (packages) and load_data.R (Demographics_unprocessed).
# Produces: Demographics, one row per candidate.
# As in the original code (analysis-plan.md section 8).

## ---- clean-demographic-names
# Column names in snake case; the spreadsheet's duplicated headings (sex, race
# and ethnicity of recipient and donor) become numbered names, renamed here.
Demographics <- Demographics_unprocessed %>%
  clean_names() %>%
  rename(recipient_age_yrs = age_yrs) %>%
  rename(recipient_sex = sex_10) %>%
  rename(recipient_race = race_11) %>%
  rename(recipient_ethnicity = ethnicity_12) %>%
  rename(donor_sex = sex_26) %>%
  rename(donor_race = race_27) %>%
  rename(donor_ethnicity = ethnicity_28)

## ---- derive-recipient-measures
# Panel reactive antibody, and time on dialysis in years (years plus months
# divided by 12; a missing month count is 0).
Demographics <- Demographics %>%
  mutate(PRA_1 = str_first_number(class_i_pra_percent)) %>%
  mutate(PRA_2 = str_first_number(class_ii_pra_percent)) %>%
  mutate(years_on_dialysis = str_first_number(time_on_dialysis)) %>%
  mutate(months_on_dialysis = str_nth_number(time_on_dialysis, n = 2)) %>%
  mutate(months_on_dialysis = ifelse(is.na(months_on_dialysis), 0, months_on_dialysis)) %>%
  mutate(time_on_hd_years = years_on_dialysis + (1/12) * (months_on_dialysis))

## ---- derive-donor-measures
# Donor age in years, warm ischemia in minutes, and cold ischemia in hours
# (hours plus minutes divided by 60).
Demographics <- Demographics %>%
  mutate(donor_age_years = str_first_number(donor_age)) %>%
  mutate(warm_ischemia_min = str_first_number(warm_ischemia_time)) %>%
  mutate(cold_ischemia_hours = str_first_number(cold_ischemia_time)) %>%
  mutate(cold_ischemia_min = str_nth_number(cold_ischemia_time, n = 2)) %>%
  mutate(cold_ischemia_total = cold_ischemia_hours + (1/60) * cold_ischemia_min)

## ---- derive-end-status
# End status, hepatitis C serology as negative or positive, and panel reactive
# antibody class II as zero or greater than zero.
Demographics <- Demographics %>%
  mutate(EndStatus = case_when(
    hiv_transplanted == 1 ~ "Transplanted from HIV D+ donor",
    hiv_transplanted == 0 & transplanted == 1 ~ "Transplanted from HIV D- donor",
    TRUE ~ "Not transplanted")) %>%
  mutate(recipient_hcv_binary = ifelse(str_detect(recipient_hcv, "Negative"), "Negative", "Positive")) %>%
  mutate(PRA_2_binary = ifelse(PRA_2 == 0, "Zero", "Greather than zero"))
