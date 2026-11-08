# Temperature-attributable type 1 diabetes burden | GBD 2021

**Selected R analysis code accompanying a study of type 1 diabetes mellitus (T1DM)-related burden attributable to low and high ambient temperature, 1990–2021, with point projections through 2045.**

This is a **partial methods release**, not a deposit of the complete research pipeline, manuscript, underlying GBD exports, individual-level observations, or final published results. The R scripts reorganize the methods represented in the research code and manuscript. They have not been re-run against the original study inputs as part of this release; outputs should not be assumed to reproduce any manuscript table or figure without independent verification.

## Methods included

| Module | Script | Output |
|---|---|---|
| Endpoint descriptive extracts | `scripts/01_descriptive.R` | 1990/2021 counts, age-standardized rates, supplied GBD uncertainty bounds |
| Estimated annual percentage change (EAPC) | `scripts/02_eapc.R` | Log-linear EAPC and 95% regression confidence intervals |
| Three-factor Das Gupta decomposition | `scripts/03_decomposition.R` | Population growth, population aging, and epidemiological-rate contributions |
| Nordpred age–period–cohort projections (optional) | `scripts/04_nordpred.R` | Point estimates through 2045; requires public `easyGBDR` |
| Example trend visualizations | `scripts/05_figures.R` | Global sex-stratified and SDI-stratified PDF figures |

**Scientific scope.** The burden measures are deaths, disability-adjusted life years (DALYs), and years of life lost (YLLs). The studied exposures are *Low temperature* and *High temperature* as modeled in GBD 2021. These are temperature-**attributable T1DM burden** estimates; this code does not estimate whether temperature causes new T1DM cases. It does not re-fit the GBD exposure–response curves, calculate population-attributable fractions, or estimate GBD uncertainty intervals from the underlying uncertainty draws.

## Project layout

```text
t1dm-temperature-gbd2021-code/
├── README.md
├── README.zh-CN.md
├── config.example.R
├── R/
│   ├── common.R
│   ├── eapc.R
│   └── decomposition.R
├── scripts/
│   ├── 00_check_environment.R
│   ├── 01_descriptive.R
│   ├── 02_eapc.R
│   ├── 03_decomposition.R
│   ├── 04_nordpred.R
│   └── 05_figures.R
├── tests/run_tests.R
├── data/                   # place your own GBD exports here; ignored by Git
├── outputs/                # analysis results; ignored by Git
└── PUBLISHING_CHECKLIST.md
```

## Setup

1. Install R (4.2+ is recommended for the current public `easyGBDR`; the original manuscript reports R 4.1.0). Core EAPC and decomposition modules use only base R.
2. For figures: `install.packages("ggplot2")`.
3. For optional Nordpred projections, install the **public** [`easyGBDR` repository](https://github.com/m6w9jbcjt2-cell/easyGBDR-) and its documented dependencies, following that project's installation instructions. Its current package requirements may differ from the historical study environment. No package source code is redistributed here.
4. Download appropriately licensed/accessible GBD 2021 estimates from the [IHME GBD Results Tool](https://vizhub.healthdata.org/gbd-results/); provide the data yourself.
5. Run scripts with the repository root as the working directory. Adjust `config.R` (copy of `config.example.R`) if your export uses different labels or locations.

### Expected input files

Put one or more comma-separated CSVs (optionally `.csv.gz`) in each folder:

```text
data/
  country/       # country-level GBD 2021 exported tables
  region/        # Global + SDI/region GBD 2021 exported tables
  population/
    population.csv  # only needed for the independent decomposition module
```

Country/region CSV columns after normalization:

`location, sex, age, year, measure, metric, rei, cause, val` (required) and `lower, upper` (optional GBD 95% uncertainty limits). Column aliases such as `location_name`, `age_name`, `measure_name`, `metric_name`, `rei_name`, `cause_name`, `sex_name`, and `year_id` are also accepted. `metric` should contain `Number` or `Rate`; rate values are per 100,000 persons. Data must retain **unrounded point estimates** for EAPC. CSVs are assumed to contain standard single-header tabular exports, rather than archived metadata blocks. Avoid overlapping or duplicate exports.

For decomposition, `data/population/population.csv` must contain one row for every required `location × sex × year × age` and columns:

`location, sex, year, age, population`

`population` must be a **population count in persons**, not a rate. Supply age-specific population values from a consistent GBD population source for 1990 and 2021; do **not** derive population by dividing rounded attributable counts by rates. The 20 age groups are listed in `config.example.R`. Missing age cells cause an explicit error. Population data are not included in this repository.

The default exposure labels, cause, outcome labels, and grouping identifiers follow the provided analysis scripts; confirm exact labels against your downloaded GBD export before execution.

## Run

From the repository root:

```bash
Rscript scripts/00_check_environment.R
Rscript tests/run_tests.R
Rscript scripts/01_descriptive.R
Rscript scripts/02_eapc.R
Rscript scripts/05_figures.R
# Optional, after supplying age-specific population data:
Rscript scripts/03_decomposition.R
# Optional, after installing the public easyGBDR package:
Rscript scripts/04_nordpred.R
```

All generated tables and figures are written to `outputs/`. The source data, local configuration, and outputs are excluded from version control by `.gitignore`. No local absolute Windows paths are used.

## Statistical details and caveats

**EAPC.** For each complete 1990–2021 age-standardized annual-rate series, fit `log(ASR) = α + β × year`. Report `100 × (exp(β) − 1)` with a 95% confidence interval transformed from the regression coefficient's t-based interval. The point estimates are *not* rounded prior to transformation and no zero offset is used. Incomplete annual series, zero or negative rates, or non-finite values are reported as `not estimable` through `status`, not modeled with a pseudo-count. A regression confidence interval is **not** the GBD 95% uncertainty interval.

**Decomposition.** For an age-specific rate `r` per 100,000 and population share `s`, reconstructed total burden is `P × Σ(s × r / 100,000)`. The contribution of population size, age composition, and age-specific attributable rate is averaged over all six possible factor-substitution orders (symmetric Das Gupta decomposition). Each contribution is additive; the exact sum is checked through `reconstruction_error`. Note that these totals are reconstructed from the supplied rates and population data and may differ slightly from separately downloaded GBD number estimates.

**Nordpred.** The forecasting module calls the public `easyGBDR::GBDnorpred_prediction()` with `predyear = 2045`, separate sex strata, and age-specific input. It exports point projections and, when plotting dependencies are available, a PDF. It requires suitable population/model support from that package. It explicitly rejects zero-valued cells pending an informed modeling choice and does not silently delete them. **No projection prediction intervals or propagated GBD uncertainty are provided.** Population assumptions and function behavior should be verified against the installed package version. This public subset does **not** include the manuscript's separate 1990–2010 training / 2011–2021 back-testing workflow; do not present the scripts as implementing that validation.

**Figures.** PDF figures demonstrate graphical methods and may not match the layout or labels of manuscript figures. GBD 95% uncertainty limits are preserved in descriptive tables where present; these scripts do not recompute them from 1,000 draws. Geographic maps from the original working files are not bundled in this selected release.

## Reproducibility and data policy

- This release contains **no research data**, private libraries, source manuscript, tracked revisions, author contact details, or historical filesystem paths.
- The package versions used for the published computations, exact input file snapshots, population projection assumptions, and output comparisons have **not been verified** in this prepared repository. Follow `PUBLISHING_CHECKLIST.md` before identifying it as the complete reproducible companion to the paper.
- Please comply with [IHME GBD Terms of Use](https://www.healthdata.org/data-tools-practices/data-practices/terms-and-conditions) and cite the appropriate GBD 2021 sources when using their estimates.
- See the public [easyGBDR package repository](https://github.com/m6w9jbcjt2-cell/easyGBDR-) for third-party implementation details. This repository does not claim authorship of that package.

## Licensing

**No open-source license has been selected for this draft release.** Public visibility on GitHub does not itself grant reuse, modification, or redistribution rights. The code owner should add an explicit `LICENSE` after choosing the appropriate permissions and confirming ownership/coauthor requirements.
