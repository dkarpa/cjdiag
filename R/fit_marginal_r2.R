# ---- Marginal R-squared Importance (Jenke et al. 2021) ----
#
# Per-respondent, per-attribute adjusted R² and per-respondent, per-level
# coefficients from regressing the choice outcome on dummies for each
# attribute separately. Provides individual-level importance from choices.
#
# resolution = "levels" (default): returns per-level coefficients (individual
#   AMCEs) averaged across respondents, with attribute R² as context.
# resolution = "attributes": returns per-attribute R² only.
#
# Reference: Jenke, Bansak, Hainmueller & Hangartner (2021),
# "Using Eye-Tracking to Understand Decision-Making in Conjoint Experiments",
# Political Analysis 29:75-101.

#' Internal helper
#' @keywords internal
#' @noRd
.fit_marginal_r2 <- function(formula, data, resp_id, resolution = "levels",
                             seed, ...) {

  parsed <- .parse_formula(formula, data)
  outcome_col <- parsed$outcome
  attributes <- parsed$attributes

  if (!resp_id %in% names(data)) {
    stop(sprintf("resp_id column '%s' not found in data", resp_id), call. = FALSE)
  }

  # Validate binary outcome
  y <- data[[outcome_col]]
  if (is.factor(y)) {
    if (length(levels(y)) != 2) {
      stop("Outcome must be binary for marginal_r2 method", call. = FALSE)
    }
    data[[outcome_col]] <- as.numeric(y) - 1L
  } else if (is.logical(y)) {
    data[[outcome_col]] <- as.integer(y)
  } else if (is.numeric(y)) {
    if (!all(y[!is.na(y)] %in% c(0, 1))) {
      stop("Outcome must be binary (0/1) for marginal_r2 method", call. = FALSE)
    }
  } else {
    stop("Outcome must be numeric (0/1), factor, or logical", call. = FALSE)
  }

  data <- data[!is.na(data[[outcome_col]]), ]

  for (a in attributes) {
    data[[a]] <- as.factor(data[[a]])
  }

  respondents <- unique(data[[resp_id]])
  n_resp <- length(respondents)
  resp_list <- split(data, data[[resp_id]])

  # Build level map: attribute -> levels (reference = first level)
  level_map <- list()
  for (a in attributes) {
    lvls <- levels(data[[a]])
    level_map[[a]] <- lvls
  }

  # All non-reference levels (what lm() estimates coefficients for)
  all_levels <- do.call(rbind, lapply(attributes, function(a) {
    lvls <- level_map[[a]]
    data.frame(attribute = a, level = lvls,
               is_reference = c(TRUE, rep(FALSE, length(lvls) - 1)),
               stringsAsFactors = FALSE)
  }))

  # ---- Core loop: per-respondent regressions ----
  # Store R² per attribute and coefficients per level
  r2_matrix <- matrix(NA_real_, nrow = n_resp, ncol = length(attributes),
                      dimnames = list(as.character(respondents), attributes))

  non_ref <- all_levels[!all_levels$is_reference, ]
  coef_key <- paste0(non_ref$attribute, non_ref$level)
  coef_matrix <- matrix(NA_real_, nrow = n_resp, ncol = nrow(non_ref),
                        dimnames = list(as.character(respondents), coef_key))

  for (a in attributes) {
    lvls <- level_map[[a]]
    expected_coefs <- paste0(a, lvls[-1])  # lm names: attributeLevel

    for (i in seq_along(respondents)) {
      rid <- as.character(respondents[i])
      resp_data <- resp_list[[rid]]

      resp_levels <- unique(resp_data[[a]])
      if (nrow(resp_data) < 3 || length(resp_levels) < 2) next

      if (length(unique(resp_data[[outcome_col]])) < 2) {
        r2_matrix[i, a] <- 0
        coef_matrix[i, expected_coefs[expected_coefs %in% colnames(coef_matrix)]] <- 0
        next
      }

      fit <- tryCatch(
        stats::lm(stats::as.formula(paste(outcome_col, "~", a)),
                  data = resp_data),
        error = function(e) NULL
      )
      if (is.null(fit)) next

      r2_matrix[i, a] <- max(suppressWarnings(summary(fit))$adj.r.squared, 0)

      # Extract coefficients for non-reference levels
      cf <- stats::coef(fit)
      for (cname in expected_coefs) {
        if (cname %in% names(cf) && cname %in% colnames(coef_matrix)) {
          coef_matrix[i, cname] <- cf[[cname]]
        }
      }
    }
  }

  # ---- Build results ----
  if (resolution == "levels") {
    # Level-specific results: per-level mean coef, abs coef, sd, with attr R²
    level_results <- do.call(rbind, lapply(attributes, function(a) {
      lvls <- level_map[[a]]
      attr_r2 <- mean(r2_matrix[, a], na.rm = TRUE)

      rows <- lapply(lvls, function(lv) {
        cname <- paste0(a, lv)
        is_ref <- (lv == lvls[1])

        if (is_ref) {
          # Reference level: coefficient is 0 by definition
          data.frame(
            attribute = a, level = lv, reference = TRUE,
            mean_coef = 0, mean_abs_coef = 0, sd_coef = 0, pct_nonzero = 0,
            attr_mean_r2 = attr_r2, stringsAsFactors = FALSE
          )
        } else if (cname %in% colnames(coef_matrix)) {
          vals <- coef_matrix[, cname]
          valid <- !is.na(vals)
          data.frame(
            attribute = a, level = lv, reference = FALSE,
            mean_coef = mean(vals[valid]),
            mean_abs_coef = mean(abs(vals[valid])),
            sd_coef = stats::sd(vals[valid]),
            pct_nonzero = sum(vals[valid] != 0) / sum(valid) * 100,
            attr_mean_r2 = attr_r2, stringsAsFactors = FALSE
          )
        } else {
          data.frame(
            attribute = a, level = lv, reference = FALSE,
            mean_coef = NA, mean_abs_coef = NA, sd_coef = NA,
            pct_nonzero = NA, attr_mean_r2 = attr_r2,
            stringsAsFactors = FALSE
          )
        }
      })
      do.call(rbind, rows)
    }))

    results <- tibble::as_tibble(level_results) %>%
      dplyr::arrange(dplyr::desc(mean_abs_coef)) %>%
      dplyr::mutate(rank = dplyr::row_number()) %>%
      dplyr::select(rank, attribute, level, reference, mean_coef,
                    mean_abs_coef, sd_coef, pct_nonzero, attr_mean_r2)

    # Also build attr_map for consistency
    attr_map <- tibble::tibble(
      var_name  = paste0(all_levels$attribute, all_levels$level),
      attribute = all_levels$attribute,
      level     = all_levels$level
    )

  } else {
    # Attribute-level results (original behavior)
    results <- tibble::tibble(
      attribute = attributes,
      mean_r2   = colMeans(r2_matrix, na.rm = TRUE),
      median_r2 = apply(r2_matrix, 2, stats::median, na.rm = TRUE),
      sd_r2     = apply(r2_matrix, 2, stats::sd, na.rm = TRUE),
      pct_zero  = colMeans(r2_matrix == 0, na.rm = TRUE) * 100
    ) %>%
      dplyr::arrange(dplyr::desc(mean_r2)) %>%
      dplyr::mutate(rank = dplyr::row_number()) %>%
      dplyr::select(rank, attribute, mean_r2, median_r2, sd_r2, pct_zero)

    attr_map <- NULL
  }

  n_total_levels <- sum(vapply(attributes, function(a) length(levels(data[[a]])), integer(1)))

  structure(
    list(
      method      = "marginal_r2",
      resolution  = resolution,
      results     = results,
      r2_matrix   = r2_matrix,
      coef_matrix = if (resolution == "levels") coef_matrix else NULL,
      n_resp      = n_resp,
      n_obs       = nrow(data),
      n_levels    = n_total_levels,
      seed        = as.integer(seed),
      formula     = formula,
      outcome     = outcome_col,
      attributes  = attributes,
      attr_map    = attr_map
    ),
    class = c("cjdiag_marginal_r2", "cjdiag_fit", "list")
  )
}
