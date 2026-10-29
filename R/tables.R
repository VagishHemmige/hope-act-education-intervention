# Purpose: build the published tables and save them to tables/.
# Needs: functions.R (save_table, relabel_levels), setup.R (tables_dir),
#   process_offers.R (organ_offers_processed), process_demographics.R
#   (Demographics) and models.R (m1, m2).
# Produces: the tables below, as gtsummary objects and as HTML files in
#   tables/, which Git ignores until the decider clears them for release.
# The tables are those of the original code (analysis-plan.md section 8),
# labelled with the wording of the published tables. The labels change only
# what is displayed: the data, the models and every number are unchanged.

## ---- count-candidates-and-donors
# How many distinct candidates received offers, and from how many donors?
offer_counts <- tibble(
  candidates_with_offers = length(unique(organ_offers_processed$PX_ID)),
  distinct_donors = length(unique(organ_offers_processed$Donor_ID))
)

## ---- display-labels-offers
# Display copy of the offers, with the paper's names for the period, the
# acceptance categories and the refusal codes. Category order is unchanged.
# The paper marks with a dagger the refusal codes counted as potentially
# HIV-related.
period_labels <- c("FALSE" = "Pre-intervention", "TRUE" = "Post-intervention")

offers_for_tables <- organ_offers_processed %>%
  mutate(
    Post_Intervention = relabel_levels(Post_Intervention, period_labels),
    Offer_Acceptance = relabel_levels(Offer_Acceptance,
                                      c("Provisional Acceptance" = "Provisional")),
    Primary_Refusal_Reason = relabel_levels(Primary_Refusal_Reason, c(
      "Candidate requires multiple organ transplant" = "Candidate requires multiple organ transplants",
      "Donor age or quality" = "Donor quality†",
      "Donor medical history, specify" = "Donor medical history, specify†",
      "Donor social history" = "Donor social history†",
      "Epidemic/Pandemic - Donor" = "Epidemic/Pandemic – Donor",
      "Patient txed, tx in progress, or other offer being considered" =
        "Patient transplanted, transplant in progress, or other offer being considered",
      "Positive infectious disease screening test: CMV, HBV, HCV, etc." =
        "Positive infectious disease screening test: CMV, HBV, HCV, etc.†"
    ))
  )

# Row labels, by variable; each table uses those of the variables it shows.
offer_labels <- list(
  HIV_Pos_to_Pos = "HIV-positive donor to HIV-positive recipient",
  Match_Date = "Match Date",
  Offer_Acceptance = "Offer Acceptance",
  Primary_Refusal_Reason = "Primary Refusal Reason",
  Post_Intervention = "Intervention period",
  organ_was_transplanted = "Organ was ultimately transplanted at another center",
  Potential_HIV_Donor_decline = "Potential HIV Donor decline"
)

hiv_code_note <- "† Refusal codes counted as a potentially HIV-related decline."

## ---- table-offers-overall
table_offers_overall <- offers_for_tables %>%
  select(HIV_Pos_to_Pos, Match_Date, Offer_Acceptance, Primary_Refusal_Reason, Post_Intervention,
         organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_summary(label = offer_labels,
              statistic = list(Match_Date ~ "{min} to {max}")) %>%
  modify_header(label ~ "**Offer characteristic**") %>%
  modify_source_note(hiv_code_note)

## ---- table-offers-by-period
# Paper Table 2. Match dates are shown as a range, as in the paper.
table_offers_by_period <- offers_for_tables %>%
  select(Match_Date, Offer_Acceptance, Primary_Refusal_Reason, Post_Intervention,
         organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_summary(by = Post_Intervention,
              label = offer_labels[c("Match_Date", "Offer_Acceptance", "Primary_Refusal_Reason",
                                     "organ_was_transplanted", "Potential_HIV_Donor_decline")],
              statistic = list(Match_Date ~ "{min} to {max}")) %>%
  add_p() %>%
  modify_header(label ~ "**Offer characteristic**") %>%
  modify_source_note(hiv_code_note) %>%
  modify_caption("**Pre and post-intervention data**")

## ---- table-declined-offers-by-period
# Offers that were declined
table_declined_by_period <- offers_for_tables %>%
  filter(Offer_Acceptance == "No") %>%
  # Show only the categories present among declined offers, as the original did
  mutate(across(c(Offer_Acceptance, Primary_Refusal_Reason), droplevels)) %>%
  select(HIV_Pos_to_Pos, Match_Date, Offer_Acceptance, Primary_Refusal_Reason, Post_Intervention,
         organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_summary(by = Post_Intervention,
              label = offer_labels[c("HIV_Pos_to_Pos", "Match_Date", "Offer_Acceptance",
                                     "Primary_Refusal_Reason", "organ_was_transplanted",
                                     "Potential_HIV_Donor_decline")],
              statistic = list(Match_Date ~ "{min} to {max}")) %>%
  add_p() %>%
  modify_header(label ~ "**Offer characteristic**") %>%
  modify_source_note(hiv_code_note) %>%
  modify_caption("**Pre and post-intervention data**")

## ---- table-declined-transplanted-elsewhere
# Among declined offers: was the donor's organ transplanted, by period and by
# whether the decline was potentially HIV-related
table_declined_transplanted <- offers_for_tables %>%
  filter(Offer_Acceptance == "No") %>%
  mutate(Potential_HIV_Donor_decline = relabel_levels(
    Potential_HIV_Donor_decline,
    c("FALSE" = "Other reason", "TRUE" = "Potentially HIV-related")
  )) %>%
  select(Post_Intervention, organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_strata(
    strata = Post_Intervention,
    .tbl_fun =
      ~ .x %>%
        tbl_summary(by = Potential_HIV_Donor_decline,
                    label = offer_labels["organ_was_transplanted"]) %>%
        add_n(),
    .header = "**{strata}**, N = {n}"
  ) %>%
  modify_caption("**Organ acceptance elsewhere in patients whose reason for decline was HIV-related, stratified by intervention period**")

## ---- table-transplant-rate-models
# Incidence rate ratios, post- vs pre-intervention
model_label <- list(Post_Intervention = "Post-intervention (vs pre-intervention)")
table_model_all_transplants <- m1 %>%
  tbl_regression(exponentiate = TRUE, label = model_label,
                 show_single_row = Post_Intervention)
table_model_hiv_transplants <- m2 %>%
  tbl_regression(exponentiate = TRUE, label = model_label,
                 show_single_row = Post_Intervention)

## ---- display-labels-demographics
# Display copy of the candidate data: end status in the paper's column order,
# and categories as the paper prints them.
demographics_for_tables <- Demographics %>%
  mutate(
    EndStatus = factor(EndStatus, levels = c("Not transplanted",
                                             "Transplanted from HIV D+ donor",
                                             "Transplanted from HIV D- donor")),
    across(c(recipient_race, recipient_ethnicity),
           \(x) relabel_levels(x, c("Unkown" = "Unknown"))),
    PRA_2_binary = relabel_levels(PRA_2_binary, c("Greather than zero" = "Greater than zero")),
    dcd_or_dbd = relabel_levels(dcd_or_dbd, c("DBD" = "Donation after brain death",
                                              "DCD" = "Donation after cardiac death"))
  )

candidate_labels <- list(
  recipient_age_yrs = "Recipient age (years)",
  recipient_sex = "Recipient sex",
  recipient_race = "Recipient race",
  recipient_ethnicity = "Recipient ethnicity",
  recipient_hcv_binary = "Recipient Hepatitis C serology",
  time_on_hd_years = "Time on dialysis (years)",
  PRA_1 = "Panel Reactive Antibody class I",
  PRA_2_binary = "Panel Reactive Antibody class II"
)

# Cold ischemia time is in hours (hours plus minutes divided by 60); the
# paper's table labels it minutes.
donor_labels <- list(
  warm_ischemia_min = "Warm ischemia time (min)",
  cold_ischemia_total = "Cold ischemia time (hours)",
  donor_sex = "Donor sex",
  donor_race = "Donor race",
  donor_ethnicity = "Donor ethnicity",
  donor_hcv = "Donor Hepatitis C serology",
  donor_age_years = "Donor age (years)",
  dcd_or_dbd = "Deceased-donor type",
  terminal_creatinine = "Terminal creatinine (mg/dl)"
)

## ---- table-candidate-characteristics
# Paper Supplemental Table 1: medians (IQR) and n (%), by end status
table_candidates <- demographics_for_tables %>%
  select(starts_with("recipient"), time_on_hd_years, PRA_1, PRA_2_binary, EndStatus) %>%
  select(-recipient_hcv) %>%
  tbl_summary(by = EndStatus, label = candidate_labels) %>%
  add_p() %>%
  bold_labels() %>%
  add_overall() %>%
  modify_header(label ~ "**Characteristic of candidates**")

## ---- table-donor-characteristics
# Paper Supplemental Table 2: among transplanted candidates, by donor HIV status
table_donors <- demographics_for_tables %>%
  filter(!EndStatus == "Not transplanted") %>%
  mutate(EndStatus = droplevels(EndStatus)) %>%
  select(warm_ischemia_min, cold_ischemia_total, starts_with("donor"), dcd_or_dbd, terminal_creatinine, EndStatus) %>%
  select(-donor_age) %>%
  tbl_summary(by = EndStatus, label = donor_labels) %>%
  add_p() %>%
  bold_labels() %>%
  add_overall() %>%
  modify_header(label ~ "**Donor or transplant characteristic**")

## ---- tables-means-not-in-paper
# Not in the paper: the same two tables with means (SD), one-way ANOVA and
# t-tests, kept from the original code while issue #4 is open.
table_candidates_means <- demographics_for_tables %>%
  select(starts_with("recipient"), time_on_hd_years, PRA_1, PRA_2_binary, EndStatus) %>%
  select(-recipient_hcv) %>%
  tbl_summary(by = EndStatus, label = candidate_labels,
              statistic = list(all_continuous() ~ "{mean} ({sd})"),
              digits = all_continuous() ~ 1) %>%
  add_p(test = all_continuous() ~ "aov") %>%
  bold_labels() %>%
  add_overall() %>%
  modify_header(label ~ "**Characteristic of candidates**")

table_donors_means <- demographics_for_tables %>%
  filter(!EndStatus == "Not transplanted") %>%
  mutate(EndStatus = droplevels(EndStatus)) %>%
  select(warm_ischemia_min, cold_ischemia_total, starts_with("donor"), dcd_or_dbd, terminal_creatinine, EndStatus) %>%
  select(-donor_age) %>%
  tbl_summary(by = EndStatus, label = donor_labels,
              statistic = list(all_continuous() ~ "{mean} ({sd})"),
              digits = all_continuous() ~ 1) %>%
  add_p(test = all_continuous() ~ "t.test") %>%
  bold_labels() %>%
  add_overall() %>%
  modify_header(label ~ "**Donor or transplant characteristic**")

## ---- save-tables
# Saved to tables/, which stays out of Git until the outputs are cleared.
dir.create(tables_dir, showWarnings = FALSE)
write_csv(offer_counts, file.path(tables_dir, "offer-counts.csv"))
save_table(table_offers_overall, "offers-overall", tables_dir)
save_table(table_offers_by_period, "table-2-offers-by-period", tables_dir)
save_table(table_declined_by_period, "declined-offers-by-period", tables_dir)
save_table(table_declined_transplanted, "declined-offers-transplanted-elsewhere", tables_dir)
save_table(table_model_all_transplants, "model-all-transplants", tables_dir)
save_table(table_model_hiv_transplants, "model-hiv-transplants", tables_dir)
save_table(table_candidates, "supplemental-table-1-candidates", tables_dir)
save_table(table_donors, "supplemental-table-2-donors", tables_dir)
save_table(table_candidates_means, "not-in-paper-candidates-means", tables_dir)
save_table(table_donors_means, "not-in-paper-donors-means", tables_dir)
