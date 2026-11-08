# Example, reproducible SDI and sex trends from the submitted analysis.
# Visualization only; it does not recompute GBD attributable fractions.
source("R/common.R")
load_project_config()
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Install the CRAN package 'ggplot2' to make figures")
}

region <- read_study_data("region")
region <- region[region$location %in% c("Global", SDI_LOCATIONS) &
                   region$sex %in% c("Both", "Male", "Female") &
                   ((region$age == "All ages" & region$metric == "Number") |
                    (region$age == "Age-standardized" & region$metric == "Rate")),
                 , drop = FALSE]
if (!nrow(region)) stop("No observations for selected figure strata")

make_figure <- function(x, title, filename) {
  x$location <- factor(x$location, levels = c("Global", SDI_LOCATIONS))
  x$rei <- factor(x$rei, levels = RISKS)
  p <- ggplot2::ggplot(x, ggplot2::aes(x = year, y = val, color = location,
                                     group = location)) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::facet_grid(measure ~ rei, scales = "free_y") +
    ggplot2::labs(title = title, x = "Year", y = "GBD estimate",
                  color = "Location / SDI") +
    ggplot2::theme_bw(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")
  ggplot2::ggsave(file.path(OUTPUT_DIR, filename), plot = p,
                  width = 13, height = 10)
  message("Wrote: ", file.path(OUTPUT_DIR, filename))
}

sdi <- region[region$sex == "Both" & region$age == "Age-standardized" &
                region$metric == "Rate", , drop = FALSE]
if (nrow(sdi)) make_figure(sdi, "Age-standardized rates by SDI", "sdi_rate_trends.pdf")

sex <- region[region$location == "Global" & region$sex %in% c("Male", "Female") &
                region$age == "Age-standardized" & region$metric == "Rate", , drop = FALSE]
if (nrow(sex)) {
  p <- ggplot2::ggplot(sex, ggplot2::aes(x = year, y = val, color = sex)) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::facet_grid(measure ~ rei, scales = "free_y") +
    ggplot2::labs(title = "Global age-standardized rates by sex",
                  x = "Year", y = "Rate per 100,000", color = "Sex") +
    ggplot2::theme_bw(base_size = 11)
  ggplot2::ggsave(file.path(OUTPUT_DIR, "global_sex_rate_trends.pdf"),
                  plot = p, width = 13, height = 10)
}
