# Analysis plan: a multispecialty educational intervention to improve acceptance of organs from donors with HIV

Status: draft. The analyses were completed and published before this plan was written [@swaminathan2025hope]; the plan records what the published analysis did, so that the rebuilt code can reproduce it.

## Scope

This document is the authoritative specification of the study's scientific objectives, populations, definitions and statistical methods. `ARCHITECTURE.md` documents the implementation, `AGENTS.md` the working conventions, and GitHub Issues the open decisions and implementation status. Neither file supersedes this plan.

**Reproduction rule.** The rebuilt code reproduces the published numbers. Where the paper and the original code differ, the code that produced the published numbers is followed, and the difference is recorded on the website's "Differences from the original code" page. Any change from what was published is a decision for the decider (`AGENTS.md`), made in a decision issue.

## 1. Objective

To evaluate whether a multispecialty educational intervention, delivered at a single transplant center in December 2020, was followed by greater acceptance of organs from deceased donors with HIV (D+) for candidates with HIV (R+) under the HOPE Act, and by a higher rate of transplantation among the center's HOPE candidates.

Questions, as in the paper [@swaminathan2025hope]:

1. Did the proportion of declined D+ offers declined for potentially HIV-related reasons fall after the intervention? (Primary offer-level measure.)
2. Did the share of offers provisionally accepted, and the share that became D+/R+ transplants at the center, change?
3. Among declined offers, how often was the donor's organ transplanted elsewhere, before and after, overall and for potentially HIV-related declines?
4. Did the rate of transplants per patient-year on the waiting list change, for all transplants and for D+/R+ transplants?
5. How did candidates who were not transplanted, transplanted from D+ donors, and transplanted from D− donors compare, and how did the D+ and D− transplants compare?

No hypotheses were registered before the analysis. All questions are reported as in the paper; none is a confirmatory test.

## 2. Design

A single-center before-and-after comparison of a quality-improvement intervention: a pre-intervention period (March 2018 to November 2020) and a post-intervention period (December 2020 to April 2022), as stated in the paper. The intervention itself, and how its barriers were identified, are described in the paper and are not part of this analysis. The design cannot separate the intervention's effect from national trends in the use of D+ organs over the same period; this is a limitation (section 11), not an estimand.

## 3. Data sources

Three restricted files, all identifiable and covered by the IRB-approved study protocol; none is in the repository (`AGENTS.md`, Data sources):

| File | Content | Unit |
|---|---|---|
| `organ-offers-clean.xls` | Offers from D+ donors to the center's candidates, from the metrics the center submitted to UNOS, with OPTN refusal codes as used at the time | Offer row (candidate × donor match) |
| `subjects-clean-2022-05-04.xlsx` | Candidates who consented to the center's HOPE listing: consent date, end of follow-up, transplant date, whether transplanted and whether from a D+ donor, listing status | Candidate |
| `demographics-2023-09-18.xlsx` | Candidate characteristics and, for transplanted candidates, donor and procedure characteristics | Candidate |

Two restricted values were removed from the code for patient privacy and are kept with the data (section 10): the intervention date, which is day 0 for both periods, and one record-level correction.

Linkage: offers are linked to candidates' study IDs by candidate last name, as in the original code. An identifier would be better practice; names are used only inside the join (decided 29 October 2026; `AGENTS.md`).

Secondary-data declaration: the investigators analyzed these files before this plan was written, and the results are published [@swaminathan2025hope].

## 4. Study populations

**Candidates.** All candidates who consented to the center's HOPE listing during the study period (23 in the paper). No exclusions are applied.

**Offers.** All offers from D+ donors to those candidates from March 2018 to April 2022 (122 offers from 85 donors to 12 candidates in the paper). Record-level processing, in order, none of which is an exclusion of a candidate:

1. The match date is read as a date.
2. Duplicate offers of the same donor to the same candidate (same candidate ID and donor ID) are reduced to one, keeping the first row.
3. One accepted offer is recoded as a provisional acceptance, because the recipient became ineligible before transplant. The record and the reason are in the restricted corrections file.

## 5. Exposure: intervention period

Each offer and each candidate-day is assigned to the pre- or post-intervention period by comparison with day 0, the intervention date, read from the restricted parameters file:

- an offer is post-intervention when its match date is after day 0;
- a candidate-day is post-intervention when the day starts after day 0.

The paper describes the periods by month (section 2). The code uses the exact intervention date, so its boundary need not fall at the start of a month; where the two differ, the code is followed.

## 6. Comparator

The pre-intervention period.

## 7. Outcomes

**Offer level.**

- *Offer acceptance:* No, Provisional Acceptance, or Yes, as recorded (after the correction in section 4).
- *Primary refusal reason:* the OPTN refusal code recorded for the offer.
- *Potentially HIV-related decline:* among offers with acceptance No, a primary refusal reason in the list below; missing for offers not declined. The list is as in the code, which matches the four codes the paper names, with the first under the name it has in the data (the paper calls it "Donor quality"):
  - "Donor age or quality"
  - "Donor medical history, specify"
  - "Donor social history"
  - "Positive infectious disease screening test: CMV, HBV, HCV, etc."
- *Donor organ transplanted:* at least one kidney from the offer's donor was transplanted, at any center; a missing count is counted as not transplanted.

**Candidate level.**

- *Follow-up:* each candidate contributes one record per day from the consent date to the end of follow-up (the number of days between them).
- *Transplant:* a transplant is counted on the day whose end equals the transplant date; all other days count 0.
- *D+/R+ transplant:* as for transplant, counting only transplants from D+ donors.
- *End status:* not transplanted; transplanted from a D+ donor; transplanted from a D− donor.

## 8. Statistical analysis

All analyses use R; the version used for each run is recorded with its outputs.

**Offer characteristics (paper Table 2).** Counts of distinct candidates and distinct donors with offers. The offer variables of section 7 summarized overall and by period, with tests by period, using `gtsummary` defaults: n (%) for categorical variables and range for the match date; Wilcoxon rank-sum for the date, and Pearson's chi-squared or Fisher's exact test for categorical variables, as `gtsummary` chooses.

**Declined offers.** The same summary restricted to offers with acceptance No. Among declined offers, the share whose donor organ was transplanted, by period and by whether the decline was potentially HIV-related.

**Transplant rates.** Poisson regression of the daily transplant indicator on period, one record per candidate-day, so that the rate is per candidate-day; the incidence rate ratio (post vs pre) with its 95% confidence interval and P value, as reported by `gtsummary::tbl_regression(exponentiate = TRUE)`. Two models: all transplants, and D+/R+ transplants.

**Open:** standard errors that account for repeated days within a candidate (the original Stata code clustered by candidate; the published R models did not), as an addition to the published models ([#3](../../issues/3)).

**Candidate characteristics (paper Supplemental Table 1).** Recipient age, sex, race, ethnicity, hepatitis C serology, time on dialysis (years plus months divided by 12), panel reactive antibody class I, and class II as zero or greater than zero, by end status, with an overall column: median (IQR) and n (%), with `gtsummary` default tests.

**Donor and transplant characteristics (paper Supplemental Table 2).** Among transplanted candidates, by donor HIV status: warm ischemia time (minutes), cold ischemia time (hours plus minutes divided by 60), donor sex, race, ethnicity, hepatitis C serology and age, donation after brain or cardiac death, and terminal creatinine; median (IQR) and n (%), with `gtsummary` default tests.

**Open:** whether the original code's alternative tables with means (SD), one-way ANOVA and t-tests, which were not published, are kept as unpublished extras or dropped ([#4](../../issues/4)).

**Patient timeline (paper Supplemental Figure 1).** For each candidate, follow-up before and after day 0 as line segments, with offers (declined; accepted but not transplanted; accepted and transplanted) and end events (transplant from a D− donor, death, permanent delisting, end of study period) as points, on a time axis of days from day 0. Published only as set out in section 10.

**Missing data.** Analyses use the records as they are; no imputation. Each table reports missing values as `gtsummary` does by default.

## 9. Sensitivity analyses

None were published. Any addition (for example [#3](../../issues/3)) is decided in its issue and labelled as not in the paper.

## 10. Disclosure control

The data are covered by the IRB-approved study protocol. In addition, for patient privacy (decided 29 October 2026):

- **Restricted values.** The intervention date, any person-level date, record identifiers, and the timeline's random seed are never in the repository. With exact day offsets, the intervention date would give each candidate's event dates. The code reads them from the restricted folder, and this plan and the website describe each in words.
- **Patient timeline.** The published Supplemental Figure 1 is a static image, from which event times can be read to within about two days. Nothing published here is more precise than what is already public: the timeline may be shown interactively only with each event moved by its own random shift of up to ±2 days, from a seed kept with the restricted values, since a public seed would let the shifts be regenerated and removed.
- **Small cells.** Until the decider sets a small-cell rule, nothing derived from the data is published except numbers that appear in the paper.

**Open:** a small-cell rule for any output not in the paper ([#5](../../issues/5)).

## 11. Limitations to address in reporting

- A before-and-after design at one center cannot separate the intervention from secular trends, including national growth in D+ organ use and changes in OPTN allocation during the study period.
- Potentially HIV-related declines are inferred from OPTN refusal codes that were not designed to record HIV status; in particular the donor quality code is broad.
- Small numbers: 23 candidates, 122 offers and 7 D+/R+ transplants, giving wide confidence intervals.
- The Poisson models treat each candidate-day as independent ([#3](../../issues/3)).
- The post-intervention period overlaps the COVID-19 pandemic, which affected refusal reasons and candidate availability.

## References

::: {#refs}
:::
