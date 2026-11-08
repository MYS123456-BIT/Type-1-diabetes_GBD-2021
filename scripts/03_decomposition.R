# Das Gupta symmetric population / age / rate decomposition.
# Requires an independently supplied age-specific population CSV.
source("R/common.R")
source("R/decomposition.R")
load_project_config()

region <- read_study_data("region")
pop <- read_population_file(file.path(DATA_DIR, "population", "population.csv"))
ans <- decompose_gbd(region, pop, AGE_GROUPS,
                     locations = DECOMPOSITION_LOCATIONS,
                     sexes = DECOMPOSITION_SEXES,
                     first_year = START_YEAR, last_year = END_YEAR)
write_output(ans, "decomposition_1990_2021.csv")
message("Maximum absolute reconstruction error: ",
        max(abs(ans$reconstruction_error)))
