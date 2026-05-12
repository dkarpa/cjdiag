# ---- Main Fitting Functions for Conjoint Diagnostic Models ----
#
# cj_fit() is the only exported fitting function. It dispatches to
# .fit_forest() or .fit_tree() based on the `method` argument.

#' Fit Conjoint Diagnostic Model
#'
#' Fits a random forest or decision tree model to conjoint data. Use
#' `resolution = "levels"` (default) for level-specific analysis where each
#' attribute level becomes a separate binary predictor, or
#' `resolution = "attributes"` for attribute-level analysis where original
#' factor columns are passed directly to the model.
#'
#' @param formula A formula of the form `choice ~ attr1 + attr2 + ...`
#'   where the outcome is binary (0/1 or a 2-level factor) and predictors
#'   are categorical attributes (converted to factors internally).
#' @param data A data frame containing the conjoint data.
#' @param method Model type: `"forest"` (default), `"tree"`, `"crt"`, `"nmm"`,
#'   or `"marginal_r2"`.
#' @param resolution Analysis resolution: `"levels"` (default) for
#'   level-specific dummy-coded analysis, or `"attributes"` for
#'   attribute-level analysis using original factors.
#' @param ntree Number of trees for random forest (default 500). Ignored
#'   when `method = "tree"`.
#' @param cp Complexity parameter for decision tree (default 0.005). Ignored
#'   when `method = "forest"`.
#' @param lambda_grid Numeric vector of lambda values for CRT regularization
#'   path (default `c(1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40, 50, 75, 100, 150, 200, 300, 400, 500)`).
#'   Ignored when `method` is not `"crt"`.
#' @param n_folds Number of cross-validation folds for CRT (default 5).
#'   Ignored when `method` is not `"crt"`.
#' @param n_perm Number of permutation rounds for CRT importance (default 20).
#'   Ignored when `method` is not `"crt"`.
#' @param tol Convergence tolerance for HierNet (default 1e-3). Ignored
#'   when `method` is not `"crt"`.
#' @param resp_id Character string naming the respondent ID column. Required
#'   when `method = "nmm"` or `"marginal_r2"`. Ignored for other methods.
#' @param n_boot Number of bootstrap iterations for NMM confidence intervals
#'   (default 0 = no bootstrap). Ignored when `method` is not `"nmm"`.
#' @param seed Random seed for reproducibility (default 42).
#' @param ... Additional arguments passed to [randomForest::randomForest()]
#'   or [rpart::rpart()].
#'
#' @return An S3 object inheriting from `cjdiag_fit`, with subclass depending
#'   on `method` (e.g., `cjdiag_forest`, `cjdiag_tree`, etc.). All objects
#'   support [print()], [plot()], [summary()], and [importance()].
#'
#' @section Methods:
#' \describe{
#'   \item{`"forest"` (Random Forest)}{Which attribute levels matter most
#'   for choices? Measures how much each attribute level matters by shuffling
#'   its values and checking how much worse predictions get (Mean Decrease in
#'   Accuracy). Also tracks which level appears first across hundreds of
#'   trees (root node rate) — a proxy for which cue respondents check first.
#'   Returns class-specific importance (class_0, class_1) showing whether a
#'   level matters more for rejection or selection. Supports both level and
#'   attribute resolution.}
#'
#'   \item{`"tree"` (Decision Tree)}{How do respondents structure their
#'   decisions? Fits a single classification tree that reveals the hierarchical
#'   structure of choices — which attribute acts as the gatekeeper, which
#'   attributes matter only conditionally, and how many attributes are needed
#'   to explain most choices. Supports both resolutions.}
#'
#'   \item{`"crt"` (CRT/HierNet)}{Which attribute levels survive a strict
#'   signal-vs-noise test? Applies increasing amounts of statistical penalty
#'   to strip away weak signals (Bien and Tibshirani 2014). Levels that keep
#'   their effect even under heavy penalization carry signal; levels that
#'   vanish quickly are noise or redundant. Levels only.}
#'
#'   \item{`"nmm"` (Nested Marginal Means)}{In what order do attributes
#'   settle choices? Works through attributes one at a time, starting with the
#'   most decisive (Dill, Howlett and Mueller-Crepon 2024). At each step,
#'   identifies the attribute level that most strongly tips choices away from
#'   50/50, removes tasks where that level cannot discriminate, and repeats.
#'   Requires `resp_id`. Levels only.}
#'
#'   \item{`"marginal_r2"` (Marginal R-squared)}{Which attributes did each
#'   respondent actually use? For each individual respondent, measures how
#'   well each attribute alone explains their choices (Jenke, Bansak,
#'   Hainmueller and Hangartner 2021). Respondents with zero explanatory
#'   power for an attribute likely ignored it entirely. Requires `resp_id`.}
#'
#' }
#'
#' @family model-fitting
#' @export
#'
#' @examples
#' \donttest{
#' data(immig)
#' rf <- cj_fit(Chosen_Immigrant ~ Gender + Education + LanguageSkills +
#'              Job + JobPlans, data = immig, method = "forest")
#' print(rf)
#' plot(rf)
#' summary(rf)
#'
#' tr <- cj_fit(Chosen_Immigrant ~ Gender + Education + LanguageSkills +
#'              Job + JobPlans, data = immig, method = "tree")
#' plot(tr)
#' }
cj_fit <- function(formula, data, method = c("forest", "tree", "crt", "nmm",
                                              "marginal_r2"),
                   resolution = c("levels", "attributes"),
                   ntree = 500L, cp = 0.005,
                   lambda_grid = c(1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40, 50, 75, 100, 150, 200, 300, 400, 500),
                   n_folds = 5L, n_perm = 20L, tol = 1e-3,
                   resp_id = NULL, n_boot = 0L,
                   seed = 42L, ...) {

  method <- match.arg(method)
  resolution <- match.arg(resolution)

  if (method == "crt" && resolution == "attributes") {
    cli_abort(c(
      "CRT method only supports {.arg resolution} = {.val levels}.",
      "i" = "Use {.code method = 'forest'} or {.code method = 'tree'} for attribute-level resolution."
    ))
  }

  if (method == "nmm" && resolution == "attributes") {
    cli_abort(c(
      "NMM method only supports {.arg resolution} = {.val levels}.",
      "i" = "Use {.code method = 'forest'} or {.code method = 'tree'} for attribute-level resolution."
    ))
  }

  if (method == "nmm" && is.null(resp_id)) {
    cli_abort(c(
      "NMM method requires {.arg resp_id} (respondent ID column name).",
      "i" = "Example: {.code cj_fit(..., method = 'nmm', resp_id = 'CaseID')}"
    ))
  }

  if (method == "marginal_r2" && is.null(resp_id)) {
    cli_abort(c(
      "{.code marginal_r2} method requires {.arg resp_id} (respondent ID column name).",
      "i" = "Example: {.code cj_fit(..., method = 'marginal_r2', resp_id = 'CaseID')}"
    ))
  }

  if (!is.data.frame(data)) {
    cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }
  if (nrow(data) == 0) {
    cli_abort("{.arg data} has no rows.")
  }

  set.seed(seed)

  if (method == "nmm") {
    prep <- .prepare_data_nmm(formula, data, resp_id = resp_id)
    return(.fit_nmm(prep, n_boot = n_boot, seed = seed, verbose = FALSE))
  }

  if (method == "marginal_r2") {
    return(.fit_marginal_r2(formula, data, resp_id = resp_id,
                            resolution = resolution, seed = seed, ...))
  }

  if (resolution == "levels") {
    prep <- .prepare_data(formula, data)
    predictor_cols <- setdiff(names(prep$dummy_data), ".outcome")

    if (method == "forest") {
      .fit_forest(prep, predictor_cols, ntree = ntree, seed = seed, ...)
    } else if (method == "tree") {
      .fit_tree(prep, predictor_cols, cp = cp, seed = seed, ...)
    } else {
      .fit_crt(prep, predictor_cols, lambda_grid = lambda_grid,
               n_folds = n_folds, n_perm = n_perm, seed = seed,
               tol = tol, ...)
    }
  } else {
    prep <- .prepare_data_attributes(formula, data)

    if (method == "forest") {
      .fit_forest_attr(prep, ntree = ntree, seed = seed, ...)
    } else {
      .fit_tree_attr(prep, cp = cp, seed = seed, ...)
    }
  }
}


# ---- Random Forest Fitting ----

#' Internal helper
#' @keywords internal
#' @noRd
.fit_forest <- function(prep, predictor_cols, ntree, seed, ...) {

  y <- as.factor(prep$dummy_data$.outcome)
  x <- prep$dummy_data[, predictor_cols, drop = FALSE]

  model <- randomForest::randomForest(
    x = x,
    y = y,
    ntree = ntree,
    importance = TRUE,
    ...
  )

  # Extract importance metrics
  imp_raw <- as.data.frame(randomForest::importance(model))
  imp_raw$var_name <- rownames(imp_raw)

  # Root node distribution
  root_dist <- .get_root_distribution(model)

  # Build results tibble
  results <- prep$attr_map %>%
    dplyr::left_join(imp_raw, by = "var_name") %>%
    dplyr::left_join(
      root_dist %>%
        dplyr::select(var_name = level, root_count = count, root_pct = pct),
      by = "var_name"
    ) %>%
    dplyr::mutate(
      root_count = ifelse(is.na(root_count), 0L, as.integer(root_count)),
      root_pct = ifelse(is.na(root_pct), 0, root_pct)
    ) %>%
    dplyr::rename(
      mda = MeanDecreaseAccuracy,
      mdg = MeanDecreaseGini,
      class_0 = `0`,
      class_1 = `1`
    ) %>%
    dplyr::arrange(dplyr::desc(mda)) %>%
    dplyr::mutate(rank = dplyr::row_number()) %>%
    dplyr::select(rank, attribute, level, mda, mdg, root_pct,
                  class_0, class_1, var_name)

  structure(
    list(
      model      = model,
      method     = "forest",
      resolution = "levels",
      results    = tibble::as_tibble(results),
      root_dist  = root_dist,
      oob_error  = as.numeric(model$err.rate[ntree, "OOB"]),
      ntree      = as.integer(ntree),
      seed       = as.integer(seed),
      formula    = prep$formula,
      outcome    = prep$outcome,
      attributes = prep$attributes,
      n_obs      = prep$n_obs,
      n_levels   = prep$n_levels,
      attr_map   = prep$attr_map
    ),
    class = c("cjdiag_forest", "cjdiag_fit", "list")
  )
}


# ---- Decision Tree Fitting ----

#' Internal helper
#' @keywords internal
#' @noRd
.fit_tree <- function(prep, predictor_cols, cp, seed, ...) {

  tree_formula <- stats::as.formula(
    paste(".outcome ~", paste(predictor_cols, collapse = " + "))
  )

  # Convert 0/1 dummies to factors so rpart treats them as categorical
  # (avoids ">= 0.5" splits in rpart.plot)
  tree_data <- prep$dummy_data
  for (col in predictor_cols) {
    tree_data[[col]] <- factor(tree_data[[col]], levels = c(0, 1))
  }

  model <- rpart::rpart(
    tree_formula,
    data = tree_data,
    control = rpart::rpart.control(cp = cp),
    ...
  )

  # Extract tree diagnostics
  root_split <- as.character(model$frame$var[1])
  n_terminal <- sum(model$frame$var == "<leaf>")
  node_nums <- as.numeric(rownames(model$frame))
  depth <- max(floor(log2(node_nums)))

  # Variable importance (may be NULL for trivial trees)
  var_imp <- model$variable.importance
  if (is.null(var_imp)) {
    var_imp <- stats::setNames(rep(0, length(predictor_cols)), predictor_cols)
  }

  imp_df <- data.frame(
    var_name = names(var_imp),
    importance = as.numeric(var_imp),
    stringsAsFactors = FALSE
  )

  # Build results tibble
  results <- prep$attr_map %>%
    dplyr::left_join(imp_df, by = "var_name") %>%
    dplyr::mutate(importance = ifelse(is.na(importance), 0, importance)) %>%
    dplyr::arrange(dplyr::desc(importance)) %>%
    dplyr::mutate(rank = dplyr::row_number()) %>%
    dplyr::select(rank, attribute, level, importance, var_name)

  structure(
    list(
      model      = model,
      method     = "tree",
      resolution = "levels",
      results    = tibble::as_tibble(results),
      root_split = root_split,
      depth      = as.integer(depth),
      n_terminal = as.integer(n_terminal),
      cp         = cp,
      seed       = as.integer(seed),
      formula    = prep$formula,
      outcome    = prep$outcome,
      attributes = prep$attributes,
      n_obs      = prep$n_obs,
      n_levels   = prep$n_levels,
      attr_map   = prep$attr_map
    ),
    class = c("cjdiag_tree", "cjdiag_fit", "list")
  )
}


# ---- Attribute-Level Random Forest ----

#' Internal helper
#' @keywords internal
#' @noRd
.fit_forest_attr <- function(prep, ntree, seed, ...) {

  y <- as.factor(prep$data[[prep$outcome]])
  x <- prep$data[, prep$attributes, drop = FALSE]

  model <- randomForest::randomForest(
    x = x,
    y = y,
    ntree = ntree,
    importance = TRUE,
    ...
  )

  # Extract importance metrics
  imp_raw <- as.data.frame(randomForest::importance(model))
  imp_raw$attribute <- rownames(imp_raw)

  # Root node distribution (attribute names)
  root_dist <- .get_root_distribution(model)

  # Build results tibble
  results <- imp_raw %>%
    dplyr::left_join(
      root_dist %>%
        dplyr::select(attribute = level, root_pct = pct),
      by = "attribute"
    ) %>%
    dplyr::mutate(root_pct = ifelse(is.na(root_pct), 0, root_pct)) %>%
    dplyr::rename(
      mda = MeanDecreaseAccuracy,
      mdg = MeanDecreaseGini,
      class_0 = `0`,
      class_1 = `1`
    ) %>%
    dplyr::arrange(dplyr::desc(mda)) %>%
    dplyr::mutate(rank = dplyr::row_number()) %>%
    dplyr::select(rank, attribute, mda, mdg, root_pct, class_0, class_1)

  structure(
    list(
      model      = model,
      method     = "forest",
      resolution = "attributes",
      results    = tibble::as_tibble(results),
      root_dist  = root_dist,
      oob_error  = as.numeric(model$err.rate[ntree, "OOB"]),
      ntree      = as.integer(ntree),
      seed       = as.integer(seed),
      formula    = prep$formula,
      outcome    = prep$outcome,
      attributes = prep$attributes,
      n_obs      = prep$n_obs,
      n_levels   = length(prep$attributes),
      attr_map   = NULL
    ),
    class = c("cjdiag_forest", "cjdiag_fit", "list")
  )
}


# ---- Attribute-Level Decision Tree ----

#' Internal helper
#' @keywords internal
#' @noRd
.fit_tree_attr <- function(prep, cp, seed, ...) {

  tree_formula <- stats::as.formula(
    paste(prep$outcome, "~", paste(prep$attributes, collapse = " + "))
  )

  model <- rpart::rpart(
    tree_formula,
    data = prep$data,
    control = rpart::rpart.control(cp = cp),
    ...
  )

  # Extract tree diagnostics
  root_split <- as.character(model$frame$var[1])
  n_terminal <- sum(model$frame$var == "<leaf>")
  node_nums <- as.numeric(rownames(model$frame))
  depth <- max(floor(log2(node_nums)))

  # Variable importance (may be NULL for trivial trees)
  var_imp <- model$variable.importance
  if (is.null(var_imp)) {
    var_imp <- stats::setNames(rep(0, length(prep$attributes)), prep$attributes)
  }

  results <- tibble::tibble(
    attribute  = names(var_imp),
    importance = as.numeric(var_imp)
  ) %>%
    dplyr::arrange(dplyr::desc(importance)) %>%
    dplyr::mutate(rank = dplyr::row_number()) %>%
    dplyr::select(rank, attribute, importance)

  structure(
    list(
      model      = model,
      method     = "tree",
      resolution = "attributes",
      results    = results,
      root_split = root_split,
      depth      = as.integer(depth),
      n_terminal = as.integer(n_terminal),
      cp         = cp,
      seed       = as.integer(seed),
      formula    = prep$formula,
      outcome    = prep$outcome,
      attributes = prep$attributes,
      n_obs      = prep$n_obs,
      n_levels   = length(prep$attributes),
      attr_map   = NULL
    ),
    class = c("cjdiag_tree", "cjdiag_fit", "list")
  )
}


# ---- Helper: Root Node Distribution ----

#' Extract root node split distribution from random forest
#'
#' @keywords internal
#'
#' Loops over all trees and records which variable appears as the first split.
#'
#' @param rf_model A randomForest model object
#' @return A tibble with columns: level (var_name), count, pct
#' @noRd
.get_root_distribution <- function(rf_model) {
  n_trees <- rf_model$ntree
  roots <- character(n_trees)

  for (i in seq_len(n_trees)) {
    tree_df <- randomForest::getTree(rf_model, k = i, labelVar = TRUE)
    roots[i] <- as.character(tree_df[1, "split var"])
  }

  root_table <- as.data.frame(table(roots), stringsAsFactors = FALSE)
  names(root_table) <- c("level", "count")
  root_table$pct <- round(root_table$count / n_trees * 100, 2)
  root_table <- root_table[order(-root_table$count), ]
  rownames(root_table) <- NULL

  tibble::as_tibble(root_table)
}
