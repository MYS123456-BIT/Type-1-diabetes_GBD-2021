# Log-linear EAPC of age-standardized GBD rates, 1990–2021.
# Strictly positive, complete annual series only (no pseudo-count).
source("R/common.R")
source("R/eapc.R")
load_project_config()

country <- read_study_data("country")
rates <- country[country$age == "Age-standardized" &
                   country$metric == "Rate", , drop = FALSE]
if (!nrow(rates)) stop("No age-standardized rate observations in country input")
result <- compute_eapc(rates, START_YEAR, END_YEAR)
write_output(result, "eapc_country_1990_2021.csv")
message("Estimable: ", sum(result$status == "estimated"),
        "; not estimable: ", sum(result$status != "estimated"))
