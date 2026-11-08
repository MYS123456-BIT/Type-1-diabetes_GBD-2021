# Shared input/output helpers. This file uses only base R.
load_project_config <- function() {
  if (!file.exists("config.example.R")) {
    stop("Run scripts from the repository root (the folder containing README.md).")
  }
  source("config.example.R", local = .GlobalEnv)
  if (file.exists("config.R")) source("config.R", local = .GlobalEnv)
  dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
}

require_columns <- function(x, cols, context = "data") {
  missing <- setdiff(cols, names(x))
  if (length(missing)) {
    stop(context, " is missing required columns: ", paste(missing, collapse = ", "))
  }
  invisible(TRUE)
}

read_gbd_csv_dir <- function(folder) {
  if (!dir.exists(folder)) stop("Data folder not found: ", folder)
  files <- list.files(folder, pattern = "\\.csv(\\.gz)?$", full.names = TRUE,
                      recursive = TRUE, ignore.case = TRUE)
  if (!length(files)) stop("No CSV or CSV.GZ files found in: ", folder)
  pieces <- lapply(files, function(path) {
    tryCatch(utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                             fileEncoding = "UTF-8-BOM"),
             error = function(e) stop("Cannot read ", path, ": ", conditionMessage(e)))
  })
  all_cols <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  pieces <- lapply(pieces, function(x) {
    for (nm in setdiff(all_cols, names(x))) x[[nm]] <- NA
    x[all_cols]
  })
  x <- do.call(rbind, pieces)
  rownames(x) <- NULL

  aliases <- c(measure_name = "measure", location_name = "location",
               sex_name = "sex", age_name = "age", cause_name = "cause",
               rei_name = "rei", metric_name = "metric", year_id = "year")
  for (alias in names(aliases)) {
    standard <- unname(aliases[[alias]])
    if (alias %in% names(x) && !(standard %in% names(x))) {
      names(x)[names(x) == alias] <- standard
    }
  }
  require_columns(x, c("year", "location", "sex", "age", "measure",
                       "metric", "rei", "cause", "val"), folder)
  for (col in intersect(c("val", "lower", "upper", "year"), names(x))) {
    x[[col]] <- suppressWarnings(as.numeric(x[[col]]))
  }
  if (anyNA(x$year) || anyNA(x$val)) {
    stop("Missing/non-numeric year or val after CSV import: ", folder)
  }
  x
}

study_subset <- function(x, cause, risks, measures, first_year, last_year) {
  require_columns(x, c("cause", "rei", "measure", "year"))
  x <- x[x$cause == cause & x$rei %in% risks & x$measure %in% measures &
           x$year >= first_year & x$year <= last_year, , drop = FALSE]
  if (!nrow(x)) {
    stop("No matching observations. Check STUDY_CAUSE, RISKS, MEASURES, and years. ",
         "Column values must match the source CSV labels exactly.")
  }
  x
}

read_study_data <- function(part = c("country", "region")) {
  part <- match.arg(part)
  x <- read_gbd_csv_dir(file.path(DATA_DIR, part))
  study_subset(x, STUDY_CAUSE, RISKS, MEASURES, START_YEAR, END_YEAR)
}

write_output <- function(x, filename) {
  path <- file.path(OUTPUT_DIR, filename)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  message("Wrote: ", path, " (", nrow(x), " rows)")
  invisible(path)
}

# Prevent accidental mixing of overlapping exports (e.g., duplicated countries).
assert_unique_series <- function(x, key) {
  require_columns(x, key)
  if (anyDuplicated(x[key])) {
    stop("Duplicate observations for key: ", paste(key, collapse = ", "),
         ". Check overlapping or repeated CSV exports.")
  }
  invisible(TRUE)
}
