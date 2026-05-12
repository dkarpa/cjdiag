# ---- CRT/HierNet Fitting for Conjoint Diagnostic Models ----
#
# .fit_crt() fits HierNet L1-regularized logistic regression across a lambda
# grid, classifies attribute levels by robustness, and computes permutation
# importance (MDA). Depends on hierNet package for hierNet.logistic().

#' Check that hierNet is available
#'
#' @keywords internal
#' @noRd
.check_crt_dependency <- function() {
  if (!requireNamespace("hierNet", quietly = TRUE)) {
    cli_abort(c(
      "Package {.pkg hierNet} is required for {.code method = \"crt\"}.",
      "i" = "Install with: {.code install.packages(\"hierNet\")}"
    ))
  }
}

#' Fit CRT/HierNet model
#'
#' @keywords internal
#'
#' @param prep Output from .prepare_data()
#' @param predictor_cols Character vector of dummy column names
#' @param lambda_grid Numeric vector of lambda values
#' @param n_folds Number of CV folds
#' @param n_perm Number of permutation rounds for MDA
#' @param seed Random seed
#' @param tol Convergence tolerance for hierNet
#' @param ... Additional arguments (unused)
#' @return S3 object of class cjdiag_crt
#' @noRd
.fit_crt <- function(prep, predictor_cols, lambda_grid, n_folds, n_perm,
                     seed, tol, ...) {

  .check_crt_dependency()

  y <- prep$dummy_data$.outcome
  X <- as.matrix(prep$dummy_data[, predictor_cols, drop = FALSE])
  n <- nrow(X)

  # Fix constant columns (hierNet requirement)
  col_vars <- apply(X, 2, function(x) length(unique(x)))
  trouble_cols <- which(col_vars == 1)
  if (length(trouble_cols) > 0) {
    X[1, trouble_cols] <- X[1, trouble_cols] + 1e-5
  }

  # ---- Cross-validation ----
  set.seed(seed)
  fold_ids <- sample(rep(seq_len(n_folds), length.out = n))

  cv_results <- tibble::tibble(
    lambda = numeric(0),
    mean_deviance = numeric(0),
    sd_deviance = numeric(0)
  )

  for (lam in lambda_grid) {
    fold_deviances <- numeric(n_folds)

    for (fold in seq_len(n_folds)) {
      train_idx <- fold_ids != fold
      test_idx <- fold_ids == fold

      tryCatch({
        invisible(utils::capture.output(
          fit <- hierNet::hierNet.logistic(
            X[train_idx, , drop = FALSE], y[train_idx],
            lam = lam, diagonal = FALSE, step = 2,
            backtrack = 0.1, tol = tol, trace = 0
          )
        ))

        eta <- X[test_idx, , drop = FALSE] %*% (fit$bp - fit$bn)
        prob <- 1 / (1 + exp(-eta))
        y_test <- y[test_idx]

        fold_deviances[fold] <- -2 * mean(
          y_test * log(prob + 1e-10) +
            (1 - y_test) * log(1 - prob + 1e-10)
        )
      }, error = function(e) {
        fold_deviances[fold] <<- NA
      })
    }

    cv_results <- dplyr::bind_rows(cv_results, tibble::tibble(
      lambda = lam,
      mean_deviance = mean(fold_deviances, na.rm = TRUE),
      sd_deviance = stats::sd(fold_deviances, na.rm = TRUE)
    ))
  }

  # Optimal lambda and 1-SE rule
  min_idx <- which.min(cv_results$mean_deviance)
  optimal_lambda <- cv_results$lambda[min_idx]
  one_se_threshold <- cv_results$mean_deviance[min_idx] +
    cv_results$sd_deviance[min_idx]
  lambda_1se <- max(cv_results$lambda[cv_results$mean_deviance <= one_se_threshold])

  # ---- Lambda path: coefficients at each lambda ----
  path_coefs <- matrix(0, nrow = length(predictor_cols),
                       ncol = length(lambda_grid),
                       dimnames = list(predictor_cols, as.character(lambda_grid)))

  for (i in seq_along(lambda_grid)) {
    lam <- lambda_grid[i]
    tryCatch({
      invisible(utils::capture.output(
        fit <- hierNet::hierNet.logistic(
          X, y, lam = lam, diagonal = FALSE, step = 2,
          backtrack = 0.1, tol = tol, trace = 0
        )
      ))
      path_coefs[, i] <- (fit$bp - fit$bn)[seq_along(predictor_cols)]
    }, error = function(e) {
      # leave zeros
    })
  }

  # Max lambda survived per level
  max_lambda_survived <- apply(path_coefs, 1, function(row) {
    nonzero_lambdas <- lambda_grid[abs(row) > 1e-6]
    if (length(nonzero_lambdas) == 0) 0 else max(nonzero_lambdas)
  })

  # ---- Final model at optimal lambda ----
  invisible(utils::capture.output(
    final_fit <- hierNet::hierNet.logistic(
      X, y, lam = optimal_lambda, diagonal = FALSE, step = 2,
      backtrack = 0.1, tol = tol, trace = 0
    )
  ))

  final_coefs <- (final_fit$bp - final_fit$bn)[seq_along(predictor_cols)]
  names(final_coefs) <- predictor_cols

  # ---- Permutation importance (MDA) ----
  # Use optimal lambda model
  eta_baseline <- as.vector(X %*% final_coefs)
  prob_baseline <- 1 / (1 + exp(-eta_baseline))
  pred_baseline <- ifelse(prob_baseline > 0.5, 1, 0)
  accuracy_baseline <- mean(pred_baseline == y)

  set.seed(seed)
  mda_values <- numeric(length(predictor_cols))
  names(mda_values) <- predictor_cols

  for (j in seq_along(predictor_cols)) {
    acc_perms <- numeric(n_perm)

    for (p in seq_len(n_perm)) {
      X_perm <- X
      X_perm[, j] <- sample(X[, j])
      eta_perm <- as.vector(X_perm %*% final_coefs)
      prob_perm <- 1 / (1 + exp(-eta_perm))
      pred_perm <- ifelse(prob_perm > 0.5, 1, 0)
      acc_perms[p] <- mean(pred_perm == y)
    }

    mda_values[j] <- 100 * (accuracy_baseline - mean(acc_perms)) /
      accuracy_baseline
  }

  # ---- Build results tibble ----
  results <- prep$attr_map %>%
    dplyr::mutate(
      mda = mda_values[var_name],
      coefficient = final_coefs[var_name],
      abs_coefficient = abs(final_coefs[var_name]),
      max_lambda = max_lambda_survived[var_name],
      attended = abs(final_coefs[var_name]) > 1e-6
    ) %>%
    dplyr::arrange(dplyr::desc(mda)) %>%
    dplyr::mutate(rank = dplyr::row_number()) %>%
    dplyr::select(rank, attribute, level, mda, coefficient, abs_coefficient,
                  max_lambda, attended, var_name)

  structure(
    list(
      model          = final_fit,
      method         = "crt",
      resolution     = "levels",
      results        = tibble::as_tibble(results),
      path_coefs     = path_coefs,
      cv_results     = cv_results,
      lambda_grid    = lambda_grid,
      optimal_lambda = optimal_lambda,
      lambda_1se     = lambda_1se,
      accuracy       = accuracy_baseline,
      seed           = as.integer(seed),
      n_perm         = as.integer(n_perm),
      n_folds        = as.integer(n_folds),
      tol            = tol,
      formula        = prep$formula,
      outcome        = prep$outcome,
      attributes     = prep$attributes,
      n_obs          = prep$n_obs,
      n_levels       = prep$n_levels,
      attr_map       = prep$attr_map
    ),
    class = c("cjdiag_crt", "cjdiag_fit", "list")
  )
}
