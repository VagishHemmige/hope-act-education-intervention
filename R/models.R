# Purpose: fit the Poisson models of transplant rate before and after the
#   intervention.
# Needs: process_person_days.R (transplant_data_processed).
# Produces: m1 (all transplants) and m2 (D+/R+ transplants).
# As published (analysis-plan.md section 8): one row per candidate-day, so the
# rate is per candidate-day, with no adjustment for repeated days within a
# candidate. Clustered standard errors are an open decision (issue #3).

## ---- fit-poisson-models
# Poisson GLM, all transplants as outcome
m1 <- glm(Transplant_Outcome ~ Post_Intervention, family = "poisson",
          data = transplant_data_processed)

# Poisson GLM, HIV D+ transplants as outcome
m2 <- glm(HIV_Transplant_Outcome ~ Post_Intervention, family = "poisson",
          data = transplant_data_processed)
