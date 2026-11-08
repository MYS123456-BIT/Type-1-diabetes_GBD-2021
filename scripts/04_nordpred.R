# Nordpred age–period–cohort point projections, using publicly available easyGBDR.
# This is the optional prediction module. It does not produce uncertainty bounds.
source("R/common.R")
load_project_config()
if (!requireNamespace("easyGBDR", quietly = TRUE)) {
  stop("Optional package easyGBDR is required for this module. See README.md.")
}

region <- read_study_data("region")
model_input <- region[region$location %in% FORECAST_LOCATIONS &
                        region$sex %in% FORECAST_SEXES &
                        region$age %in% AGE_GROUPS, , drop = FALSE]
if (!nrow(model_input)) stop("No age-specific input for Nordpred")
if (any(!is.finite(model_input$val) | model_input$val < 0)) {
  stop("Model input contains invalid or negative values; review source data")
}
# Do not silently drop zero-valued cells. Model viability must be reviewed
# for the particular age/period/exposure strata before interpretation.
if (any(model_input$val == 0)) {
  stop("Zero-valued cells present. Review and document treatment of sparse ",
       "age/period strata before fitting Nordpred (no automatic deletion).")
}
assert_unique_series(model_input, c("location", "sex", "age", "year", "rei",
                                    "measure", "metric", "cause"))
easyGBDR::GBD_edition(edition = 2021)
projection <- easyGBDR::GBDnorpred_prediction(
  data = model_input,
  measure_name = unique(model_input$measure),
  cause_name = unique(model_input$cause),
  location_name = FORECAST_LOCATIONS,
  rei_name = unique(model_input$rei),
  By_sex = TRUE,
  predyear = PROJECTION_YEAR,
  full_age_adjusted = FALSE
)
if (!all(c("all_age_projection", "ASR") %in% names(projection))) {
  stop("Unexpected prediction object. Check your installed easyGBDR version.")
}
write_output(as.data.frame(projection[["all_age_projection"]]),
             "nordpred_projected_counts.csv")
write_output(as.data.frame(projection[["ASR"]]),
             "nordpred_projected_rates.csv")

# Optional plot: API follows the public package used by the original analysis.
if (requireNamespace("ggplot2", quietly = TRUE)) {
  fig <- easyGBDR::ggprediction_Dx(
    data = projection, ratio = "auto", CI = FALSE, predict_start = END_YEAR + 1L,
    group_name = "sex", location_name = FORECAST_LOCATIONS,
    measure_name = unique(model_input$measure),
    cause_name = unique(model_input$cause), rei_name = NULL,
    sex_name = unique(model_input$sex)
  ) + ggplot2::facet_wrap(~ rei + measure, scales = "free_y") +
    ggplot2::theme_bw()
  ggplot2::ggsave(file.path(OUTPUT_DIR, "nordpred_point_projections.pdf"),
                  plot = fig, width = 13, height = 9)
}
