# ---- Print Methods for Conjoint Diagnostic Objects ----

#' Internal helper
#' @keywords internal
#' @noRd
.print_header <- function(title) {
  cat(title, "\n")
  cat(strrep("=", nchar(title)), "\n\n")
}

#' @export
print.cjdiag_forest <- function(x, n = NULL, ...) {
  n <- n %||% get_cjdiag_options("print_n") %||% 10L
  resolution <- x$resolution %||% "levels"
  .print_header("Conjoint Random Forest")
  cat(sprintf("Resolution: %s\n", resolution))
  cat(sprintf("Trees: %d\n", x$ntree))
  cat(sprintf("OOB Error: %.1f%%\n", x$oob_error * 100))
  cat(sprintf("Observations: %s\n", format(x$n_obs, big.mark = ",")))
  cat(sprintf("Attributes: %d\n", length(x$attributes)))
  if (resolution == "levels") {
    cat(sprintf("Levels: %d\n", x$n_levels))
  }
  cat("\n")

  n_show <- min(n, nrow(x$results))
  if (resolution == "levels") {
    cat("Top", n_show, "levels by MDA:\n\n")
    print(
      x$results[seq_len(n_show),
                c("rank", "attribute", "level", "mda", "root_pct",
                  "class_0", "class_1")],
      n = n
    )
  } else {
    cat("Top", n_show, "attributes by MDA:\n\n")
    print(
      x$results[seq_len(n_show),
                c("rank", "attribute", "mda", "mdg", "root_pct",
                  "class_0", "class_1")],
      n = n
    )
  }

  invisible(x)
}

#' @export
print.cjdiag_tree <- function(x, n = NULL, ...) {
  n <- n %||% get_cjdiag_options("print_n") %||% 10L
  resolution <- x$resolution %||% "levels"
  .print_header("Conjoint Decision Tree")
  cat(sprintf("Resolution: %s\n", resolution))
  cat(sprintf("Complexity (cp): %s\n", x$cp))
  cat(sprintf("Root split: %s\n", x$root_split))
  cat(sprintf("Depth: %d\n", x$depth))
  cat(sprintf("Terminal nodes: %d\n", x$n_terminal))
  cat(sprintf("Observations: %s\n", format(x$n_obs, big.mark = ",")))
  if (resolution == "levels") {
    cat(sprintf("Levels: %d\n", x$n_levels))
  }
  cat("\n")

  n_show <- min(n, nrow(x$results))
  if (resolution == "levels") {
    cat("Top", n_show, "levels by importance:\n\n")
    print(
      x$results[seq_len(n_show),
                c("rank", "attribute", "level", "importance")],
      n = n
    )
  } else {
    cat("Top", n_show, "attributes by importance:\n\n")
    print(
      x$results[seq_len(n_show),
                c("rank", "attribute", "importance")],
      n = n
    )
  }

  invisible(x)
}

#' @export
print.cjdiag_crt <- function(x, n = NULL, ...) {
  n <- n %||% get_cjdiag_options("print_n") %||% 10L
  .print_header("Conjoint CRT/HierNet Model")
  cat(sprintf("Optimal lambda: %g\n", x$optimal_lambda))
  cat(sprintf("Lambda (1-SE rule): %g\n", x$lambda_1se))
  cat(sprintf("Accuracy: %.1f%%\n", x$accuracy * 100))
  cat(sprintf("Observations: %s\n", format(x$n_obs, big.mark = ",")))
  cat(sprintf("Attributes: %d\n", length(x$attributes)))
  cat(sprintf("Levels: %d\n", x$n_levels))

  n_attended <- sum(x$results$attended)
  cat(sprintf("Attended levels: %d / %d\n", n_attended, x$n_levels))
  cat("\n")

  n_show <- min(n, nrow(x$results))
  cat("Top", n_show, "levels by MDA:\n\n")
  print(
    x$results[seq_len(n_show),
              c("rank", "attribute", "level", "mda", "max_lambda")],
    n = n
  )

  invisible(x)
}

#' @export
print.cjdiag_nmm <- function(x, n = NULL, ...) {
  n <- n %||% get_cjdiag_options("print_n") %||% 10L
  .print_header("Conjoint Nested Marginal Means")
  cat(sprintf("Observations: %s\n", format(x$n_obs, big.mark = ",")))
  cat(sprintf("Attributes: %d\n", length(x$attributes)))
  cat(sprintf("Levels: %d\n", x$n_levels))
  if (x$n_boot > 0) {
    cat(sprintf("Bootstrap iterations: %d\n", x$n_boot))
  }
  cat("\n")

  # Sample reduction summary
  sh <- x$sample_history
  total <- sh[1]
  cat(sprintf("Total pairs: %s\n", format(total, big.mark = ",")))
  if (length(sh) > 5) {
    cat(sprintf("After top 5: %s (%.1f%% remaining)\n",
                format(sh[6], big.mark = ","), 100 * sh[6] / total))
  }
  cat("\n")

  n_show <- min(n, nrow(x$results))
  cat("Top", n_show, "levels by decisiveness:\n\n")
  cols <- c("rank", "attribute", "level", "mm", "decisiveness", "pct_of_total")
  if (x$n_boot > 0) cols <- c(cols, "q025", "q975")
  print(
    x$results[seq_len(n_show), intersect(cols, names(x$results))],
    n = n
  )

  invisible(x)
}

# ---- Marginal R-squared Print Method ----

#' @export
print.cjdiag_marginal_r2 <- function(x, n = NULL, ...) {
  n <- n %||% get_cjdiag_options("print_n") %||% 10L
  .print_header("Conjoint Marginal R-squared Importance (Jenke et al. 2021)")
  cat(sprintf("Resolution: %s\n", x$resolution))
  cat(sprintf("Respondents: %s\n", format(x$n_resp, big.mark = ",")))
  cat(sprintf("Observations: %s\n", format(x$n_obs, big.mark = ",")))
  cat(sprintf("Attributes: %d (%d levels)\n", length(x$attributes), x$n_levels))
  cat("\n")

  n_show <- min(n, nrow(x$results))
  if (x$resolution == "levels") {
    cat("Top", n_show, "levels by mean absolute coefficient:\n\n")
    print(
      x$results[seq_len(n_show),
                c("rank", "attribute", "level", "mean_coef",
                  "mean_abs_coef", "sd_coef", "attr_mean_r2")],
      n = n
    )
  } else {
    cat("Attribute importance by mean adjusted R-squared:\n\n")
    print(x$results[seq_len(n_show), ], n = n)
  }

  invisible(x)
}

#' @export
print.cjdiag_importance <- function(x, n = NULL, ...) {
  n <- n %||% get_cjdiag_options("print_n") %||% 10L
  resolution <- x$resolution %||% "levels"
  .print_header("Conjoint Importance Metrics")
  cat(sprintf("Resolution: %s\n", resolution))

  if (x$method == "forest") {
    cat(sprintf("Method: Random Forest (%d trees)\n", x$ntree))
    cat(sprintf("OOB Error: %.1f%%\n\n", x$oob_error * 100))
  } else if (x$method == "tree") {
    cat("Method: Decision Tree\n")
    cat(sprintf("Root split: %s\n\n", x$root_split))
  } else if (x$method == "crt") {
    cat("Method: CRT/HierNet\n")
    cat(sprintf("Optimal lambda: %g\n", x$optimal_lambda))
    cat(sprintf("Attended levels: %d\n\n", x$n_attended))
  } else if (x$method == "nmm") {
    cat("Method: Nested Marginal Means\n")
    if (!is.null(x$n_boot) && x$n_boot > 0) {
      cat(sprintf("Bootstrap iterations: %d\n", x$n_boot))
    }
    cat("\n")
  } else if (x$method == "marginal_r2") {
    cat(sprintf("Method: Marginal R-squared (%d respondents)\n", x$n_resp))
    cat("\n")
  }

  n_show <- min(n, nrow(x$results))
  if (resolution == "attributes") {
    cat("Attribute Importance (top", n_show, "):\n\n")
  } else {
    cat("Level Importance (top", n_show, "):\n\n")
  }
  print(utils::head(x$results, n), n = n)

  invisible(x)
}

#' @export
as.data.frame.cjdiag_importance <- function(x, row.names = NULL,
                                            optional = FALSE, ...) {
  as.data.frame(x$results, row.names = row.names, optional = optional)
}


# ---- Summary Methods ----

#' @export
summary.cjdiag_forest <- function(object, ...) {
  n <- nrow(object$results)
  top3_mda <- sum(utils::head(object$results$mda, 3))
  total_mda <- sum(object$results$mda)
  cat("Conjoint Random Forest Summary\n")
  cat(sprintf("  %d trees, OOB error %.1f%%, %s obs, %d levels\n",
              object$ntree, object$oob_error * 100,
              format(object$n_obs, big.mark = ","), n))
  cat(sprintf("  Top-1 MDA: %.1f (%.0f%% of total)\n",
              object$results$mda[1], 100 * object$results$mda[1] / total_mda))
  cat(sprintf("  Top-3 MDA: %.1f (%.0f%% of total)\n",
              top3_mda, 100 * top3_mda / total_mda))
  cat(sprintf("  Root split: %s (%.1f%%)\n",
              object$results$level[1],
              object$results$root_pct[1]))
  invisible(object)
}

#' @export
summary.cjdiag_tree <- function(object, ...) {
  cat("Conjoint Decision Tree Summary\n")
  cat(sprintf("  cp=%.4f, depth=%d, %d terminal nodes\n",
              object$cp, object$depth, object$n_terminal))
  cat(sprintf("  Root split: %s\n", object$root_split))
  cat(sprintf("  Variables used: %d of %d\n",
              sum(object$results$importance > 0), nrow(object$results)))
  invisible(object)
}

#' @export
summary.cjdiag_crt <- function(object, ...) {
  n_attended <- sum(object$results$attended)
  cat("Conjoint CRT/HierNet Summary\n")
  cat(sprintf("  Optimal lambda: %g, Lambda 1-SE: %g\n",
              object$optimal_lambda, object$lambda_1se))
  cat(sprintf("  Accuracy: %.1f%%\n", object$accuracy * 100))
  cat(sprintf("  Attended: %d / %d levels (%.0f%%)\n",
              n_attended, object$n_levels,
              100 * n_attended / object$n_levels))
  invisible(object)
}

#' @export
summary.cjdiag_nmm <- function(object, ...) {
  sh <- object$sample_history
  cat("Conjoint Nested Marginal Means Summary\n")
  cat(sprintf("  %d levels ranked, %s obs\n",
              nrow(object$results), format(object$n_obs, big.mark = ",")))
  if (length(sh) > 1) {
    cat(sprintf("  After top 1: %.1f%% remaining, after top 5: %.1f%%\n",
                100 * sh[2] / sh[1],
                if (length(sh) > 5) 100 * sh[6] / sh[1] else NA))
  }
  # Cumulative % explained by top 5
  top5_pct <- sum(utils::head(object$results$pct_of_total, 5), na.rm = TRUE)
  cat(sprintf("  Top 5 levels explain %.1f%% of choices\n", top5_pct))
  invisible(object)
}

#' @export
summary.cjdiag_importance <- function(object, ...) {
  cat(sprintf("Importance Summary (%s, %s resolution)\n",
              object$method, object$resolution %||% "levels"))
  cat(sprintf("  %d entries\n", nrow(object$results)))
  invisible(object)
}
