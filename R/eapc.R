# EAPC = 100 * (exp(beta) - 1), where beta is the OLS coefficient
# from log(age-standardized rate) ~ calendar year.
# CI is a *regression* 95% confidence interval, not a GBD uncertainty interval.
# IMPORTANT: no rounding, pseudo-count or constant is applied before log().
compute_eapc <- function(x, start_year = 1990L, end_year = 2021L,
                         group_vars = c("location", "sex", "rei", "measure", "cause")) {
  require_columns(x, c(group_vars, "year", "val"), "EAPC input")
  x <- x[x$year >= start_year & x$year <= end_year, , drop = FALSE]
  if (!nrow(x)) stop("No rows in the requested EAPC year range")
  assert_unique_series(x, c(group_vars, "year"))

  # Explicit key separator to avoid conflating distinct combinations.
  keys <- do.call(paste, c(x[group_vars], list(sep = "\035")))
  split_rows <- split(seq_len(nrow(x)), keys)
  years_required <- seq.int(start_year, end_year)
  result <- lapply(split_rows, function(rows) {
    dat <- x[rows, , drop = FALSE]
    info <- dat[1L, group_vars, drop = FALSE]
    dat <- dat[order(dat$year), , drop = FALSE]
    ok_years <- identical(as.integer(dat$year), as.integer(years_required))
    ok_values <- all(is.finite(dat$val) & dat$val > 0)
    reason <- if (!ok_years) "incomplete_annual_series" else
      if (!ok_values) "nonpositive_or_nonfinite_rate" else "estimated"
    out <- data.frame(info,
                      start_year = start_year, end_year = end_year,
                      n_years = nrow(dat),
                      eapc = NA_real_, lower_95ci = NA_real_, upper_95ci = NA_real_,
                      status = reason, check.names = FALSE)
    if (reason != "estimated") return(out)
    fit <- stats::lm(log(val) ~ year, data = dat)
    beta <- unname(stats::coef(fit)["year"])
    ci <- stats::confint(fit, parm = "year", level = 0.95)
    out$eapc <- 100 * (exp(beta) - 1)
    out$lower_95ci <- 100 * (exp(ci[1L]) - 1)
    out$upper_95ci <- 100 * (exp(ci[2L]) - 1)
    out
  })
  ans <- do.call(rbind, result)
  rownames(ans) <- NULL
  ans
}
