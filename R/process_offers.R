# Purpose: prepare the offer-level data: dates, duplicate removal, period,
#   derived offer measures, the link to study IDs, and the listed correction.
# Needs: setup.R (InterventionDate, HIV_reason_list, record_corrections),
#   functions.R and load_data.R (organ_offers_unprocessed,
#   transplant_data_unprocessed).
# Produces: organ_offers_processed, one row per offer.
# The steps and their order are those of the original code (analysis-plan.md
# sections 4, 5 and 7). Two privacy changes: the correction is read from the
# restricted folder instead of being written in the code, and candidates'
# names are dropped as soon as the link to study IDs is made.

## ---- prepare-offers
organ_offers_processed <- organ_offers_unprocessed %>%
  # Convert string to date format for Match_Date
  mutate(Match_Date = mdy(Match_Date)) %>%
  # Remove duplicates: one row per candidate and donor
  distinct(PX_ID, Donor_ID, .keep_all = TRUE) %>%
  # Mark the post-intervention period
  mutate(Post_Intervention = Match_Date > InterventionDate) %>%
  # Mark whether the donor's organ was transplanted (regardless of where)
  mutate(organ_was_transplanted = case_when(
    Number_of_Kidneys_tranplanted_from_Donor >= 1 ~ TRUE,
    Number_of_Kidneys_tranplanted_from_Donor == 0 ~ FALSE,
    is.na(Number_of_Kidneys_tranplanted_from_Donor) ~ FALSE)) %>%
  # Mark whether a declined organ was declined for donor concerns potentially
  # related to HIV status
  mutate(Potential_HIV_Donor_decline = case_when(
    (Offer_Acceptance == "No") & (Primary_Refusal_Reason %in% HIV_reason_list) ~ TRUE,
    (Offer_Acceptance == "No") & !(Primary_Refusal_Reason %in% HIV_reason_list) ~ FALSE,
    !(Offer_Acceptance == "No") ~ NA)) %>%
  # Sort by donor ID
  arrange(Donor_ID)

## ---- link-offers-to-study-ids
# Offers are linked to study IDs by candidate last name, as in the original
# code (decided 29 October 2026; an identifier would be better practice).
# The original join used every column the two tables share; that is only the
# last name when the offers have no Study_ID column, which is checked here.
# Names stay inside this step and are dropped straight after the join.
if ("Study_ID" %in% names(organ_offers_processed)) {
  stop("The offers file already has a Study_ID column, so the original code's ",
       "join would also have matched on it. Check before continuing.", call. = FALSE)
}

names_Study_ID_crosswalk <- transplant_data_unprocessed %>%
  select(Study_ID, Candidate_Last_Name)

rows_before <- nrow(organ_offers_processed)
organ_offers_processed <- organ_offers_processed %>%
  left_join(names_Study_ID_crosswalk, by = "Candidate_Last_Name") %>%
  select(-Candidate_Last_Name)
check_rows_unchanged(rows_before, nrow(organ_offers_processed),
                     "Linking offers to study IDs (two candidates may share a last name)")

rm(names_Study_ID_crosswalk, rows_before)

## ---- apply-offer-corrections
# One accepted offer is recoded as a provisional acceptance, because the
# recipient became ineligible before transplant. The record's identifier is
# kept in the restricted corrections file, not here, for patient privacy.
organ_offers_processed <- apply_record_corrections(
  organ_offers_processed,
  record_corrections,
  source_name = "organ_offers",
  id_column = "Match_ID"
)
