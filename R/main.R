# Purpose: run the definitive analysis from start to finish.
# Needs: the restricted files in data-raw/ (README.md, Running the analysis).
# Produces: the tables in tables/ and the figures in figures/.
# Run from the project root, in a fresh R session.

source("R/functions.R")             # helper functions, used by setup.R's checks
source("R/setup.R")                 # packages, paths, constants, restricted values
source("R/load_data.R")             # the three restricted study files
source("R/process_person_days.R")   # one row per candidate-day
source("R/process_offers.R")        # one row per offer
source("R/process_demographics.R")  # candidate, donor and transplant characteristics
source("R/models.R")                # Poisson models of transplant rate
source("R/tables.R")                # published tables
source("R/figures.R")               # patient timeline
