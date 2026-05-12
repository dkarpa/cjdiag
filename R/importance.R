# ---- Importance Extraction ----
#
# importance() is an S3 generic that extracts importance
# metrics from fitted conjoint diagnostic models.

#' Extract Importance Metrics from Fitted Model
#'
#' Extracts importance metrics from a fitted conjoint diagnostic model.
#' Returns the results at whatever resolution the model was fitted at:
#' level-specific (if `resolution = "levels"`) or attribute-level
#' (if `resolution = "attributes"`).
#'
#' @param x A fitted model object from [cj_fit()]
#' @param ... Additional arguments (unused)
#'
#' @return A `cjdiag_importance` object (a list) containing:
#'   \item{results}{Tibble with importance metrics at the fitted resolution}
#'   \item{method}{Character: `"forest"` or `"tree"`}
#'   \item{resolution}{Character: `"levels"` or `"attributes"`}
#'
#' @family results
#' @export
#'
#' @examples
#' \donttest{
#' df <- data.frame(
#'   y = sample(0:1, 200, TRUE),
#'   a = factor(sample(c("x","y"), 200, TRUE)),
#'   b = factor(sample(c("p","q","r"), 200, TRUE))
#' )
#' rf <- cj_fit(y ~ a + b, data = df, method = "forest")
#' imp <- importance(rf)
#' print(imp)
#' as.data.frame(imp)
#' }
importance <- function(x, ...) {
  UseMethod("importance")
}

#' @export
importance.default <- function(x, ...) {
  stop("importance() is not defined for objects of class '",
       paste(class(x), collapse = "', '"), "'")
}

#' @export
importance.cjdiag_forest <- function(x, ...) {

  resolution <- x$resolution %||% "levels"

  structure(
    list(
      results    = x$results,
      root_dist  = x$root_dist,
      method     = "forest",
      resolution = resolution,
      oob_error  = x$oob_error,
      ntree      = x$ntree
    ),
    class = c("cjdiag_importance", "list")
  )
}

#' @export
importance.cjdiag_tree <- function(x, ...) {

  resolution <- x$resolution %||% "levels"

  structure(
    list(
      results    = x$results,
      method     = "tree",
      resolution = resolution,
      root_split = x$root_split,
      depth      = x$depth
    ),
    class = c("cjdiag_importance", "list")
  )
}

#' @export
importance.cjdiag_crt <- function(x, ...) {

  n_attended <- sum(x$results$attended)

  structure(
    list(
      results        = x$results,
      method         = "crt",
      resolution     = "levels",
      optimal_lambda = x$optimal_lambda,
      lambda_1se     = x$lambda_1se,
      n_attended     = n_attended,
      accuracy       = x$accuracy
    ),
    class = c("cjdiag_importance", "list")
  )
}

#' @export
importance.cjdiag_nmm <- function(x, ...) {

  structure(
    list(
      results    = x$results,
      method     = "nmm",
      resolution = "levels",
      n_boot     = x$n_boot
    ),
    class = c("cjdiag_importance", "list")
  )
}

#' @export
importance.cjdiag_marginal_r2 <- function(x, ...) {
  structure(
    list(
      results    = x$results,
      method     = "marginal_r2",
      resolution = x$resolution %||% "levels",
      n_resp     = x$n_resp,
      r2_matrix  = x$r2_matrix
    ),
    class = c("cjdiag_importance", "list")
  )
}

