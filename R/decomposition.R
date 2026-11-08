# Symmetric three-factor decomposition (Das Gupta / Shapley averaging).
# For each year: burden = population * sum(age_share * age_specific_rate / 100000).
# Every one of the 3! substitution orders is used, with equal weight.
# This implementation is independent of any non-public R package.
three_factor_decomposition <- function(pop_1990, pop_2021,
                                       rate_1990, rate_2021) {
  vectors <- list(pop_1990, pop_2021, rate_1990, rate_2021)
  if (!length(pop_1990) || any(vapply(vectors, length, integer(1)) != length(pop_1990))) {
    stop("Population and rate vectors must be non-empty and have equal lengths")
  }
  if (any(!is.finite(unlist(vectors))) || any(unlist(vectors) < 0)) {
    stop("Population and rate inputs must be finite and nonnegative")
  }
  P0 <- sum(pop_1990); P1 <- sum(pop_2021)
  if (P0 <= 0 || P1 <= 0) stop("Total population must be strictly positive")
  shares0 <- pop_1990 / P0; shares1 <- pop_2021 / P1
  states <- list(c(P0, P1), list(shares0, shares1), list(rate_1990, rate_2021))
  eval_burden <- function(which_year) {
    selected_shares <- states[[2L]][[which_year[[2L]]]]
    selected_rates <- states[[3L]][[which_year[[3L]]]]
    states[[1L]][which_year[[1L]]] * sum(selected_shares * selected_rates) / 1e5
  }
  orders <- rbind(c(1L, 2L, 3L), c(1L, 3L, 2L),
                  c(2L, 1L, 3L), c(2L, 3L, 1L),
                  c(3L, 1L, 2L), c(3L, 2L, 1L))
  contributions <- matrix(0, nrow = nrow(orders), ncol = 3L)
  for (row in seq_len(nrow(orders))) {
    current <- rep(1L, 3L)
    before <- eval_burden(current)
    for (factor in orders[row, ]) {
      current[factor] <- 2L
      after <- eval_burden(current)
      contributions[row, factor] <- after - before
      before <- after
    }
  }
  effects <- colMeans(contributions)
  first <- eval_burden(rep(1L, 3L))
  last <- eval_burden(rep(2L, 3L))
  c(burden_1990 = first, burden_2021 = last,
    overall_change = last - first,
    population_growth = effects[1L], population_aging = effects[2L],
    epidemiological_change = effects[3L],
    reconstruction_error = (last - first) - sum(effects))
}

read_population_file <- function(path) {
  if (!file.exists(path)) stop("Required population CSV not found: ", path)
  pop <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8-BOM")
  aliases <- c(location_name = "location", sex_name = "sex",
               age_name = "age", year_id = "year", val = "population")
  for (alias in names(aliases)) {
    standard <- unname(aliases[[alias]])
    if (alias %in% names(pop) && !(standard %in% names(pop))) {
      names(pop)[names(pop) == alias] <- standard
    }
  }
  require_columns(pop, c("location", "sex", "age", "year", "population"), path)
  pop$year <- suppressWarnings(as.integer(pop$year))
  pop$population <- suppressWarnings(as.numeric(pop$population))
  if (anyNA(pop$year) || anyNA(pop$population)) {
    stop("Invalid year/population in ", path)
  }
  if (any(pop$population < 0)) stop("Population must not be negative")
  pop
}

# Rates: one row per location/sex/risk/measure/year/age, metric == Rate.
# Population: one row per location/sex/year/age, as person counts.
decompose_gbd <- function(rates, population, age_groups, locations,
                          sexes = "Both", first_year = 1990L, last_year = 2021L) {
  require_columns(rates, c("location", "sex", "rei", "measure", "cause",
                           "year", "age", "val", "metric"))
  require_columns(population, c("location", "sex", "year", "age", "population"))
  if (anyDuplicated(age_groups)) stop("Duplicate AGE_GROUPS entries")
  pop <- population[population$age %in% age_groups &
                      population$year %in% c(first_year, last_year) &
                      population$location %in% locations &
                      population$sex %in% sexes, , drop = FALSE]
  assert_unique_series(pop, c("location", "sex", "year", "age"))
  rates <- rates[rates$metric == "Rate" & rates$age %in% age_groups &
                   rates$location %in% locations & rates$sex %in% sexes &
                   rates$year %in% c(first_year, last_year), , drop = FALSE]
  if (!nrow(rates)) stop("No age-specific rate data for decomposition")
  assert_unique_series(rates, c("location", "sex", "rei", "measure", "cause", "year", "age"))
  combinations <- unique(rates[c("location", "sex", "rei", "measure", "cause")])
  out <- lapply(seq_len(nrow(combinations)), function(i) {
    g <- combinations[i, , drop = FALSE]
    z <- rates[rates$location == g$location & rates$sex == g$sex &
                 rates$rei == g$rei & rates$measure == g$measure &
                 rates$cause == g$cause, , drop = FALSE]
    p <- pop[pop$location == g$location & pop$sex == g$sex, , drop = FALSE]
    get_vector <- function(tab, year, col) {
      x <- tab[tab$year == year, , drop = FALSE]
      positions <- match(age_groups, x$age)
      if (anyNA(positions) || nrow(x) != length(age_groups)) {
        stop("Missing/duplicate age group for ", g$location, " / ", g$sex,
             " / ", year, " in ", col, " data")
      }
      as.numeric(x[[col]][positions])
    }
    b <- three_factor_decomposition(
      get_vector(p, first_year, "population"),
      get_vector(p, last_year, "population"),
      get_vector(z, first_year, "val"),
      get_vector(z, last_year, "val"))
    data.frame(g, start_year = first_year, end_year = last_year,
               as.list(b), check.names = FALSE)
  })
  ans <- do.call(rbind, out)
  rownames(ans) <- NULL
  ans
}
