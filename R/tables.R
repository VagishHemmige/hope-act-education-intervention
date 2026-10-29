# Purpose: build the published tables and save them to tables/.
# Needs: functions.R (save_table), setup.R (tables_dir), process_offers.R
#   (organ_offers_processed), process_demographics.R (Demographics) and
#   models.R (m1, m2).
# Produces: the tables below, as gtsummary objects and as HTML files in
#   tables/, which Git ignores until the decider clears them for release.
# The tables are those of the original code (analysis-plan.md section 8).

## ---- count-candidates-and-donors
# How many distinct candidates received offers, and from how many donors?
offer_counts <- tibble(
  candidates_with_offers = length(unique(organ_offers_processed$PX_ID)),
  distinct_donors = length(unique(organ_offers_processed$Donor_ID))
)

## ---- table-offers-overall
table_offers_overall <- organ_offers_processed %>%
  select(HIV_Pos_to_Pos, Match_Date, Offer_Acceptance, Primary_Refusal_Reason, Post_Intervention,
         organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_summary()

## ---- table-offers-by-period
# Paper Table 2
table_offers_by_period <- organ_offers_processed %>%
  select(Match_Date, Offer_Acceptance, Primary_Refusal_Reason, Post_Intervention,
         organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_summary(by = Post_Intervention) %>%
  add_p() %>%
  modify_caption("**Pre and post-intervention data**")

## ---- table-declined-offers-by-period
# Offers that were declined
table_declined_by_period <- organ_offers_processed %>%
  filter(Offer_Acceptance == "No") %>%
  select(HIV_Pos_to_Pos, Match_Date, Offer_Acceptance, Primary_Refusal_Reason, Post_Intervention,
         organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_summary(by = Post_Intervention) %>%
  add_p() %>%
  modify_caption("**Pre and post-intervention data**")

## ---- table-declined-transplanted-elsewhere
# Among declined offers: was the donor's organ transplanted, by period and by
# whether the decline was potentially HIV-related
table_declined_transplanted <- organ_offers_processed %>%
  filter(Offer_Acceptance == "No") %>%
  select(Post_Intervention, organ_was_transplanted, Potential_HIV_Donor_decline) %>%
  tbl_strata(
    strata = Post_Intervention,
    .tbl_fun =
      ~ .x %>%
        tbl_summary(by = Potential_HIV_Donor_decline) %>%
        add_n(),
    .header = "**{strata}**, N = {n}"
  ) %>%
  modify_caption("**Organ acceptance elsewhere in patients whose reason for decline was HIV-related, stratified by intervention period**")

## ---- table-transplant-rate-models
# Incidence rate ratios, post- vs pre-intervention
table_model_all_transplants <- m1 %>% tbl_regression(exponentiate = TRUE)
table_model_hiv_transplants <- m2 %>% tbl_regression(exponentiate = TRUE)

## ---- table-candidate-characteristics
# Paper Supplemental Table 1: medians (IQR) and n (%), by end status
table_candidates <- Demographics %>%
  select(starts_with("recipient"), time_on_hd_years, PRA_1, PRA_2_binary, EndStatus) %>%
  select(-recipient_hcv) %>%
  tbl_summary(by = EndStatus) %>%
  add_p() %>%
  bold_labels() %>%
  add_overall()

## ---- table-donor-characteristics
# Paper Supplemental Table 2: among transplanted candidates, by donor HIV status
table_donors <- Demographics %>%
  filter(!EndStatus == "Not transplanted") %>%
  select(warm_ischemia_min, cold_ischemia_total, starts_with("donor"), dcd_or_dbd, terminal_creatinine, EndStatus) %>%
  select(-donor_age) %>%
  tbl_summary(by = EndStatus) %>%
  add_p() %>%
  bold_labels() %>%
  add_overall()

## ---- tables-means-not-in-paper
# Not in the paper: the same two tables with means (SD), one-way ANOVA and
# t-tests, kept from the original code while issue #4 is open.
table_candidates_means <- Demographics %>%
  select(starts_with("recipient"), time_on_hd_years, PRA_1, PRA_2_binary, EndStatus) %>%
  select(-recipient_hcv) %>%
  tbl_summary(by = EndStatus,
              statistic = list(all_continuous() ~ "{mean} ({sd})"),
              digits = all_continuous() ~ 1) %>%
  add_p(test = all_continuous() ~ "aov") %>%
  bold_labels() %>%
  add_overall()

table_donors_means <- Demographics %>%
  filter(!EndStatus == "Not transplanted") %>%
  select(warm_ischemia_min, cold_ischemia_total, starts_with("donor"), dcd_or_dbd, terminal_creatinine, EndStatus) %>%
  select(-donor_age) %>%
  tbl_summary(by = EndStatus,
              statistic = list(all_continuous() ~ "{mean} ({sd})"),
              digits = all_continuous() ~ 1) %>%
  add_p(test = all_continuous() ~ "t.test") %>%
  bold_labels() %>%
  add_overall()

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
