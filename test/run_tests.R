# Tests use only base R; no GBD data and no network connection are needed.
source("R/common.R")
source("R/eapc.R")
source("R/decomposition.R")

# 2% true log-linear annual growth across 1990--2021.
years <- 1990:2021
rates <- data.frame(location = "Test", sex = "Both", rei = "High temperature",
                    measure = "Deaths", cause = "Diabetes mellitus type 1",
                    year = years, val = 1.5 * 1.02^(years - 1990))
ans <- compute_eapc(rates)
stopifnot(nrow(ans) == 1L, ans$status == "estimated",
          abs(ans$eapc - 2) < 1e-9)

# One exact zero => no EAPC; don't fabricate via offsets or rounding.
rates$val[3L] <- 0
ans0 <- compute_eapc(rates)
stopifnot(ans0$status == "nonpositive_or_nonfinite_rate", is.na(ans0$eapc))

# Incomplete time-series => no EAPC.
ans1 <- compute_eapc(rates[-1L, ])
stopifnot(ans1$status == "incomplete_annual_series", is.na(ans1$eapc))

# Pure population growth should have no aging or rate effects.
res <- three_factor_decomposition(c(100, 200), c(200, 400),
                                  c(10, 20), c(10, 20))
stopifnot(abs(res["population_aging"]) < 1e-9,
          abs(res["epidemiological_change"]) < 1e-9,
          abs(res["overall_change"] - res["population_growth"]) < 1e-9)

# Arbitrary scenarios must sum to the precise total change.
res2 <- three_factor_decomposition(c(100, 200, 300), c(130, 220, 380),
                                   c(1.2, 3.4, 5.6), c(1.1, 4.1, 5.2))
stopifnot(abs(res2["reconstruction_error"]) < 1e-10)

message("All EAPC and decomposition unit tests passed.")
