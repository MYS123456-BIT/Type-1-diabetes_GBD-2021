# Descriptive data extracts (1990 and 2021) for countries/regions.
# The supplied uncertainty limits are GBD 95% uncertainty intervals.
source("R/common.R")
load_project_config()

for (part in c("country", "region")) {
  data <- read_study_data(part)
  data <- data[data$year %in% c(START_YEAR, END_YEAR) &
                 ((data$age == "All ages" & data$metric == "Number") |
                  (data$age == "Age-standardized" & data$metric == "Rate")), , drop = FALSE]
  if (!nrow(data)) stop("No endpoint observations: ", part)
  cols <- c("location", "sex", "age", "year", "rei", "measure", "metric",
            "val", intersect(c("lower", "upper"), names(data)))
  data <- data[order(data$location, data$rei, data$measure,
                     data$sex, data$age, data$year), cols, drop = FALSE]
  assert_unique_series(data, c("location", "sex", "age", "year", "rei",
                               "measure", "metric"))
  write_output(data, paste0("descriptive_", part, "_1990_2021.csv"))
}
