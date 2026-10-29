# Purpose: read the three restricted study files from data-raw/.
# Needs: setup.R (paths, packages) and functions.R (checks).
# Produces: organ_offers_unprocessed, transplant_data_unprocessed,
#   Demographics_unprocessed.
# The files are read exactly as in the original R Markdown file; only their
# names and location changed (see README.md). Each read checks that the
# columns the later scripts use are present, so a changed file stops the run.

## ---- check-data-files
check_files_exist(c(offers_file, subjects_file, demographics_file))

## ---- read-organ-offers
organ_offers_unprocessed <- read_excel(offers_file)

check_names_present(
  names(organ_offers_unprocessed),
  c("PX_ID", "Donor_ID", "Match_ID", "Match_Date", "Candidate_Last_Name",
    "HIV_Pos_to_Pos", "Offer_Acceptance", "Primary_Refusal_Reason",
    "Number_of_Kidneys_tranplanted_from_Donor"),
  offers_file
)

## ---- read-subjects
# Column types by position, as in the original code.
transplant_data_unprocessed <- read_excel(
  subjects_file,
  col_types = c("text", "text", "text", "text",
                "date", "date", "date", "numeric",
                "numeric", "text", "text")
)

check_names_present(
  names(transplant_data_unprocessed),
  c("Study_ID", "Candidate_Last_Name", "Date_of_consent", "End_Date",
    "Date_of_TXP", "Transplanted", "HIV_transplanted", "Listing_Status"),
  subjects_file
)
not_dates <- c("Date_of_consent", "End_Date", "Date_of_TXP") |>
  purrr::discard(\(column) inherits(transplant_data_unprocessed[[column]], "POSIXct"))
if (length(not_dates) > 0) {
  stop("In ", subjects_file, " these columns were not read as dates: ",
       paste(not_dates, collapse = ", "),
       ". Check the column order against col_types.", call. = FALSE)
}
rm(not_dates)

## ---- read-demographics
Demographics_unprocessed <- read_excel(demographics_file)
