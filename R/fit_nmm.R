# ---- Nested Marginal Means Fitting for Conjoint Diagnostic Models ----
#
# .fit_nmm() implements the sequential elimination algorithm from
# Dill, Howlett & Muller-Crepon (2022). At each step it estimates marginal
# means (OLS) for all remaining attribute levels on the non-ambiguous
# subsample, selects the most decisive level (MM furthest from 0.5),
# removes all pairs where that level differentiates, and repeats.

#' Run the NMM sequential elimination algorithm
#'
#' @keywords internal
#'
#' Estimates marginal means via OLS at each step, selects the most
#' decisive level, eliminates pairs where that level varies, and
#' iterates until no attributes remain or no variation is left.
#'
#' @param df Data frame with resp_pair, level dummies, ambiguity indicators,
#'   outcome column, and respondent ID column
#' @param vars Character vector of dummy variable names to rank
#' @param attr_map Named character vector (dummy_var_name -> attribute)
#' @param outcome Character name of outcome column
#' @param resp_id Character name of respondent ID column
#' @param verbose Logical; print progress messages
#' @return A list with: order (character vector of ranked var names),
#'   coef_history (list of coefficient vectors at each step),
#'   sample_history (numeric vector of remaining pair counts),
#'   mm_at_selection (named numeric vector of MM when each level was selected)
#' @noRd
.nmm_order <- function(df, vars, attr_map, outcome, resp_id, verbose = FALSE) {

  order <- character(0)
  drop.pairs <- character(0)
  coef_history <- list()
  sample_history <- numeric(0)
  mm_at_selection <- numeric(0)

  total_pairs <- length(unique(df$resp_pair))
  sample_history <- c(sample_history, total_pairs)

  while (length(vars) > 0) {

    # Estimate marginal means for each attribute's remaining levels
    all_coefs <- c()
    active_attrs <- unique(attr_map[vars])

    for (attr_name in active_attrs) {
      these_vars <- vars[attr_map[vars] == attr_name]

      # Skip attributes with only 1 level remaining (no contrast possible)
      if (length(these_vars) < 2) next

      amb_col <- paste0(attr_name, "_amb")
      this_df <- df[!df$resp_pair %in% drop.pairs & df[[amb_col]] == 0, ]

      # Skip if no observations remain for this attribute
      if (nrow(this_df) == 0) next

      f <- stats::as.formula(
        paste(outcome, "~ 0 +", paste(these_vars, collapse = " + "))
      )
      m <- try(stats::lm(f, data = this_df), silent = TRUE)

      if (!inherits(m, "try-error")) {
        coefs <- stats::coef(m)
        # Remove NAs (can happen with collinearity)
        coefs <- coefs[!is.na(coefs)]
        all_coefs <- c(all_coefs, coefs)
      }
    }

    # Stop if no coefficients were estimated
    if (length(all_coefs) == 0) {
      # Append remaining vars in arbitrary order
      order <- c(order, vars)
      for (v in vars) {
        mm_at_selection[v] <- NA_real_
      }
      break
    }

    # Store coefficients at this step
    coef_history <- c(coef_history, list(all_coefs))

    # Most decisive = furthest from 0.5
    decisive_var <- names(all_coefs)[which.max(abs(all_coefs - 0.5))]
    decisive_coef <- all_coefs[decisive_var]

    if (verbose) {
      message(sprintf("Rank %d: %s (MM = %.3f, decisiveness = %.3f)",
                      length(order) + 1, decisive_var, decisive_coef,
                      abs(decisive_coef - 0.5) * 2))
    }

    order <- c(order, decisive_var)
    mm_at_selection[decisive_var] <- decisive_coef

    # Determine which vars to drop: the decisive var, plus its pair if
    # only 2 dummies remain for that attribute
    decisive_attr <- attr_map[decisive_var]
    attr_vars <- vars[attr_map[vars] == decisive_attr]
    vars_to_drop <- if (length(attr_vars) == 2) attr_vars else decisive_var

    # For the paired drop, record the other var(s) after the decisive one
    other_dropped <- setdiff(vars_to_drop, decisive_var)
    for (v in other_dropped) {
      order <- c(order, v)
      # Estimate MM for paired drop from same coefficient set if available
      if (v %in% names(all_coefs)) {
        mm_at_selection[v] <- all_coefs[v]
      } else {
        mm_at_selection[v] <- NA_real_
      }
    }

    vars <- setdiff(vars, vars_to_drop)

    # Drop pairs where any dropped var = 1 AND attribute is non-ambiguous
    amb_col <- paste0(decisive_attr, "_amb")
    for (v in vars_to_drop) {
      loss <- df[[v]] == 1 & df[[amb_col]] == 0
      drop.pairs <- unique(c(drop.pairs, df$resp_pair[loss]))
    }

    remaining <- length(unique(df$resp_pair[!df$resp_pair %in% drop.pairs]))
    sample_history <- c(sample_history, remaining)
  }

  list(
    order          = order,
    coef_history   = coef_history,
    sample_history = sample_history,
    mm_at_selection = mm_at_selection
  )
}


#' Assign decision rank to each observation pair
#'
#' @keywords internal
#'
#' For each ranked level in order, marks the pairs that are eliminated
#' at that rank (where the level differentiates and the pair hasn't
#' already been eliminated).
#'
#' @param df Data frame with resp_pair, level dummies, ambiguity indicators
#' @param order Character vector of ranked variable names
#' @param attr_map Named character vector (dummy_var_name -> attribute)
#' @return Integer vector of ranks (same length as nrow(df)), NA for
#'   observations not eliminated by any ranked level
#' @noRd
.nmm_decision_rank <- function(df, order, attr_map) {

  rank_vec <- rep(NA_integer_, nrow(df))
  assigned_pairs <- character(0)

  for (i in seq_along(order)) {
    v <- order[i]
    attr_name <- attr_map[v]
    amb_col <- paste0(attr_name, "_amb")

    # Pairs where this var = 1 and attribute is non-ambiguous
    active <- df[[v]] == 1 & df[[amb_col]] == 0
    active_pairs <- unique(df$resp_pair[active])

    # Only assign to pairs not already ranked
    new_pairs <- setdiff(active_pairs, assigned_pairs)

    if (length(new_pairs) > 0) {
      rows_to_assign <- df$resp_pair %in% new_pairs & is.na(rank_vec)
      rank_vec[rows_to_assign] <- i
      assigned_pairs <- c(assigned_pairs, new_pairs)
    }
  }

  rank_vec
}


#' Fit Nested Marginal Means model
#'
#' @keywords internal
#'
#' Implements the sequential elimination algorithm from Dill, Howlett &
#' Muller-Crepon (2022). Optionally bootstraps by resampling respondents
#' to obtain confidence intervals on ranks.
#'
#' @param prep Output from .prepare_data_nmm()
#' @param n_boot Integer number of bootstrap resamples (0 = no bootstrap)
#' @param seed Random seed for reproducibility
#' @param verbose Logical; print progress messages
#' @return S3 object of class c("cjdiag_nmm", "cjdiag_fit", "list")
#' @noRd
.fit_nmm <- function(prep, n_boot = 0L, seed = 42L, verbose = TRUE) {

  df       <- prep$data
  vars     <- prep$all_vars
  attr_map <- prep$attr_map
  outcome  <- prep$outcome
  resp_id  <- prep$resp_id

  # ---- Point estimate ----
  if (verbose) message("Fitting NMM sequential elimination...")

  main_result <- .nmm_order(df, vars, attr_map, outcome, resp_id,
                            verbose = verbose)

  order          <- main_result$order
  coef_history   <- main_result$coef_history
  sample_history <- main_result$sample_history
  mm_at_sel      <- main_result$mm_at_selection

  # ---- Compute pct_of_total for each ranked level ----
  total_pairs <- length(unique(df$resp_pair))
  rank_vec <- .nmm_decision_rank(df, order, attr_map)

  # Count pairs decided at each rank
  pair_ranks <- tapply(rank_vec[!duplicated(paste0(df$resp_pair, "_", rank_vec))],
                       df$resp_pair[!duplicated(paste0(df$resp_pair, "_", rank_vec))],
                       function(x) x[!is.na(x)][1])
  # Simpler: for each pair, take the rank (first non-NA across the 2 rows)
  pair_rank_df <- stats::aggregate(
    rank_vec,
    by = list(pair = df$resp_pair),
    FUN = function(x) {
      vals <- x[!is.na(x)]
      if (length(vals) > 0) vals[1] else NA_integer_
    }
  )
  names(pair_rank_df) <- c("pair", "rank")

  rank_counts <- table(pair_rank_df$rank)

  pct_of_total <- numeric(length(order))
  for (i in seq_along(order)) {
    rk <- as.character(i)
    if (rk %in% names(rank_counts)) {
      pct_of_total[i] <- as.numeric(rank_counts[rk]) / total_pairs * 100
    } else {
      pct_of_total[i] <- 0
    }
  }

  cumulative_pct <- cumsum(pct_of_total)

  # ---- Build results tibble ----
  # Extract level label (strip "Attribute: " prefix)
  level_labels <- vapply(order, function(v) {
    lab <- prep$var_labels[[v]]
    if (is.null(lab)) return(v)
    parts <- strsplit(lab, ": ", fixed = TRUE)[[1]]
    if (length(parts) >= 2) paste(parts[-1], collapse = ": ") else lab
  }, character(1), USE.NAMES = FALSE)

  results <- tibble::tibble(
    rank           = seq_along(order),
    attribute      = as.character(attr_map[order]),
    level          = level_labels,
    mm             = as.numeric(mm_at_sel[order]),
    decisiveness   = abs(as.numeric(mm_at_sel[order]) - 0.5) * 2,
    pct_of_total   = pct_of_total,
    cumulative_pct = cumulative_pct,
    mean_rank      = NA_real_,
    q025           = NA_real_,
    q975           = NA_real_,
    var_name       = order
  )

  # ---- Bootstrap ----
  if (n_boot > 0L) {
    if (verbose) message(sprintf("Running %d bootstrap resamples...", n_boot))

    set.seed(seed)
    resp_ids <- unique(df[[resp_id]])

    # Collect rank matrix: rows = bootstrap, cols = var_names
    boot_ranks <- matrix(NA_real_, nrow = n_boot, ncol = length(vars))
    colnames(boot_ranks) <- vars

    for (b in seq_len(n_boot)) {
      if (verbose && b %% 50 == 0) {
        message(sprintf("  Bootstrap %d / %d", b, n_boot))
      }

      # Resample respondents with replacement
      sampled_ids <- sample(resp_ids, length(resp_ids), replace = TRUE)

      # Reconstruct data by joining sampled IDs back
      boot_df <- do.call(rbind, lapply(seq_along(sampled_ids), function(j) {
        rows <- df[df[[resp_id]] == sampled_ids[j], ]
        # Assign new unique resp_pair to avoid collisions from resampling
        rows$resp_pair <- paste0(j, "_", rows$resp_pair)
        rows
      }))

      boot_result <- .nmm_order(boot_df, vars, attr_map, outcome, resp_id,
                                verbose = FALSE)
      boot_order <- boot_result$order

      # Record rank for each variable
      for (k in seq_along(boot_order)) {
        v <- boot_order[k]
        if (v %in% colnames(boot_ranks)) {
          boot_ranks[b, v] <- k
        }
      }
    }

    # Compute summary statistics
    for (i in seq_along(order)) {
      v <- order[i]
      if (v %in% colnames(boot_ranks)) {
        bvals <- boot_ranks[, v]
        bvals <- bvals[!is.na(bvals)]
        if (length(bvals) > 0) {
          results$mean_rank[i]  <- mean(bvals)
          results$q025[i]       <- stats::quantile(bvals, 0.025)
          results$q975[i]       <- stats::quantile(bvals, 0.975)
        }
      }
    }

    if (verbose) message("Bootstrap complete.")
  }

  # ---- Return S3 object ----
  structure(
    list(
      method         = "nmm",
      resolution     = "levels",
      results        = results,
      sample_history = sample_history,
      coef_history   = coef_history,
      n_boot         = as.integer(n_boot),
      seed           = as.integer(seed),
      formula        = prep$formula,
      outcome        = prep$outcome,
      attributes     = prep$attributes,
      n_obs          = prep$n_obs,
      n_levels       = prep$n_levels,
      attr_map       = prep$attr_map,
      var_labels     = prep$var_labels
    ),
    class = c("cjdiag_nmm", "cjdiag_fit", "list")
  )
}
