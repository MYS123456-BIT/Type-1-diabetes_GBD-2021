# Study settings. Copy to config.R only if you need to override defaults.
# config.R and all input/output data are excluded from Git tracking.
DATA_DIR <- "data"
OUTPUT_DIR <- "outputs"
START_YEAR <- 1990L
END_YEAR <- 2021L
PROJECTION_YEAR <- 2045L
STUDY_CAUSE <- "Diabetes mellitus type 1"
RISKS <- c("Low temperature", "High temperature")
MEASURES <- c("Deaths", "DALYs (Disability-Adjusted Life Years)",
              "YLLs (Years of Life Lost)")
AGE_GROUPS <- c("<5", "5 to 9", "10 to 14", "15 to 19", "20 to 24",
                "25 to 29", "30 to 34", "35 to 39", "40 to 44",
                "45 to 49", "50 to 54", "55 to 59", "60 to 64",
                "65 to 69", "70 to 74", "75 to 79", "80 to 84",
                "85 to 89", "90 to 94", "95 plus")
SDI_LOCATIONS <- c("High SDI", "High-middle SDI", "Middle SDI",
                   "Low-middle SDI", "Low SDI")
DECOMPOSITION_LOCATIONS <- "Global"
DECOMPOSITION_SEXES <- "Both"
FORECAST_LOCATIONS <- "Global"
FORECAST_SEXES <- c("Male", "Female", "Both")
