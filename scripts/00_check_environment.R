source("R/common.R")
load_project_config()
message("R version: ", getRversion())
message("Root: ", normalizePath(".", winslash = "/"))
message("Input directory: ", DATA_DIR)
message("Output directory: ", OUTPUT_DIR)
message("Core scripts: base R; visualization: ggplot2")
for (pkg in c("ggplot2", "easyGBDR")) {
  message(pkg, ": ", if (requireNamespace(pkg, quietly = TRUE)) "installed" else "not installed")
}
for (part in c("country", "region")) {
  path <- file.path(DATA_DIR, part)
  message(path, ": ", if (dir.exists(path)) "directory exists" else "directory missing")
}
message(file.path(DATA_DIR, "population", "population.csv"), ": ",
        if (file.exists(file.path(DATA_DIR, "population", "population.csv")))
          "file exists" else "file missing (required only for decomposition)")
