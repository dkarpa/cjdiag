# ---- Tidy/Glance Methods (broom-compatible) ----
#
# These methods provide standardized tibble output compatible with the
# broom package ecosystem. They are conditionally registered in .onLoad()
# (see options.R) so broom is not a hard dependency.

#' Tidy a cjdiag_fit object
#'
#' Extract the results tibble from any cjdiag model fit.
#'
#' @param x A model object from [cj_fit()]
#' @param ... Unused
#' @return A tibble of results
#' @keywords internal
#' @noRd
tidy.cjdiag_fit <- function(x, ...) {
  x$results
}

#' Tidy a cjdiag_importance object
#'
#' @param x An importance object from [importance()]
#' @param ... Unused
#' @return A tibble of importance results
#' @keywords internal
#' @noRd
tidy.cjdiag_importance <- function(x, ...) {
  x$results
}

#' Glance at a cjdiag_fit object
#'
#' Returns a single-row tibble with model-level summaries.
#'
#' @param x A model object from [cj_fit()]
#' @param ... Unused
#' @return A single-row tibble
#' @keywords internal
#' @noRd
glance.cjdiag_fit <- function(x, ...) {
  cls <- class(x)[1]

  base <- tibble::tibble(
    method = cls,
    n_obs = x$n_obs %||% NA_integer_
  )

  if (cls == "cjdiag_forest") {
    base$ntree <- x$ntree
    base$oob_error <- x$oob_error
    base$n_attributes <- length(x$attributes)
    base$n_levels <- x$n_levels %||% NA_integer_
  } else if (cls == "cjdiag_tree") {
    base$root_split <- x$root_split
    base$depth <- x$depth
    base$n_terminal <- x$n_terminal
    base$cp <- x$cp
  } else if (cls == "cjdiag_crt") {
    base$optimal_lambda <- x$optimal_lambda
    base$lambda_1se <- x$lambda_1se
    base$accuracy <- x$accuracy
    base$n_attended <- sum(x$results$attended)
  } else if (cls == "cjdiag_nmm") {
    base$n_attributes <- length(x$attributes)
    base$n_levels <- x$n_levels
    base$n_boot <- x$n_boot
  } else if (cls == "cjdiag_marginal_r2") {
    base$n_resp <- x$n_resp
    base$n_attributes <- length(x$attributes)
  }

  base
}
