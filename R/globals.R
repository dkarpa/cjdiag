# Global variable declarations for NSE (dplyr/ggplot2 pipelines)
# Avoids R CMD check NOTEs about "no visible binding for global variable"
utils::globalVariables(c(
  # data_prep / cj_fit results columns
  "attribute", "level", "var_name",
  "mda", "mdg", "root_pct", "root_count",
  "class_0", "class_1",
  "importance",
  "MeanDecreaseAccuracy", "MeanDecreaseGini",
  "0", "1",

  # root distribution columns
  "count", "pct",

  # plotting variables
  "value", "label", "metric", "rank",
  "root_scaled", "MDA", "Root %",
  ".data",

  # CRT-specific columns
  "coefficient", "abs_coefficient", "max_lambda",
  "attended",
  "mean_deviance", "sd_deviance", "lambda",
  "lower", "upper", "status",

  # NMM-specific columns
  "mm", "decisiveness", "pct_of_total", "cumulative_pct",
  "mean_rank", "q025", "q975",
  "n_pairs", "pct_remaining", "resp_pair",

  # Marginal R-squared columns
  "mean_r2", "median_r2", "sd_r2", "pct_zero", "pct_r2_zero",
  "mean_coef", "mean_abs_coef", "sd_coef", "pct_nonzero",
  "attr_mean_r2", "attr_pct_r2_zero", "reference",

  # cumulative plot
  "cumulative_mda", "cumulative_pct", "mda_clean",

  # theme / options / faceting
  "group_by_attribute"
))
