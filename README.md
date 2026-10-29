
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![Status](https://img.shields.io/badge/status-code_release_in_progress-yellow)](#)
[![Paper](https://img.shields.io/badge/Transpl_Infect_Dis-2025-blue)](https://doi.org/10.1111/tid.70039)
<!-- badges: end -->

# A multispecialty educational intervention to improve acceptance of organs from donors with HIV

This repository releases the analysis code of a published single-center
study. A multispecialty educational intervention in December 2020 aimed
to increase the center’s acceptance of organs from donors with HIV for
candidates with HIV under the HOPE Act. The study compares the periods
before and after the intervention: organ offers and why they were
declined, the rate of transplants per patient-year on the waiting list,
and the characteristics of candidates and transplants.

> Swaminathan N, Puius YA, Czeresnia J, Muggia VA, Azzi Y, Raees H,
> Akalin E, Hemmige V. Proof of concept that implementation of a
> multispecialty educational intervention may improve acceptance of
> organs from donors with HIV at a tertiary care hospital: a
> single-center study. *Transplant Infectious Disease*. 2025;e70039.
> [doi:10.1111/tid.70039](https://doi.org/10.1111/tid.70039)

The original analysis was a single R Markdown file, kept in
[`original/`](original/) with the values that could identify patients
removed. This repository rebuilds it as scripts that reproduce the
published numbers, and documents every difference between the paper and
the original code. It contains no patient-level data and no results
beyond those in the paper.

The analysis website, which explains the code step by step, will be at:
<https://vagishhemmige.github.io/hope-act-education-intervention/>

## Documentation

- [`analysis-plan.md`](analysis-plan.md): what the analysis is meant to
  do
- [`AGENTS.md`](AGENTS.md): how to work in this repository, including
  the data and privacy rules
- [Issues](https://github.com/VagishHemmige/hope-act-education-intervention/issues):
  open decisions and known gaps

## Running the analysis

The analysis needs the study’s restricted files, which are covered by
the IRB-approved study protocol and are never in this repository. An
authorized person places them in the project’s `data-raw/` folder, which
Git ignores:

- `organ-offers-clean.xls`, `subjects-clean-2022-05-04.xlsx` and
  `demographics-2023-09-18.xlsx`: the study data.
- `restricted-parameters.yml` and `record-corrections.csv`: the values
  removed from the code for patient privacy.

Then run `R/main.R` from the project root (the scripts are being added).
Tables and figures are written to `tables/` and `figures/`, which stay
out of Git until they have been checked against the paper and cleared
for release.

Because `data-raw/` sits inside the project folder, do not connect this
folder to an AI tool. See `AGENTS.md`.
