# ---- Data Preparation for Conjoint Diagnostic Models ----
#
# Internal functions for formula parsing, validation, dummy coding,
# and attribute mapping. These form the data layer used by cj_fit().

#' Parse formula and extract outcome + attribute names
#'
#' @keywords internal
#'
#' @param formula A formula of the form `outcome ~ attr1 + attr2 + ...`
#' @param data A data frame
#' @return Named list with `outcome` (character) and `attributes` (character vector)
#' @noRd
.parse_formula <- function(formula, data) {
  if (!inherits(formula, "formula")) {
    stop("`formula` must be a formula (e.g., choice ~ attr1 + attr2)")
  }

  if (length(formula) != 3) {
    stop("Formula must have both a response and predictors ",
         "(e.g., choice ~ attr1 + attr2)")
  }

  outcome <- as.character(formula[[2]])
  attrs <- all.vars(formula[[3]])

  if (length(outcome) != 1) {
    stop("Formula must have exactly one outcome variable")
  }

  if (length(attrs) == 0) {
    stop("Formula must have at least one predictor")
  }

  # Check all variables exist in data
  all_vars <- c(outcome, attrs)
  missing_vars <- setdiff(all_vars, names(data))
  if (length(missing_vars) > 0) {
    stop("Variables not found in data: ", paste(missing_vars, collapse = ", "))
  }

  list(outcome = outcome, attributes = attrs)
}

#' Validate that outcome is binary (0/1)
#'
#' @keywords internal
#'
#' @param data A data frame
#' @param outcome Character name of outcome column
#' @return Data frame with outcome converted to numeric 0/1
#' @noRd
.validate_outcome <- function(data, outcome) {
  y <- data[[outcome]]

  if (is.factor(y)) {
    if (length(levels(y)) != 2) {
      stop("Outcome '", outcome, "' must be binary (2 levels), found ",
           length(levels(y)), " levels")
    }
    data[[outcome]] <- as.numeric(y) - 1L
  } else if (is.logical(y)) {
    data[[outcome]] <- as.integer(y)
  } else if (is.numeric(y)) {
    unique_vals <- sort(unique(y[!is.na(y)]))
    if (!all(unique_vals %in% c(0, 1))) {
      stop("Outcome '", outcome, "' must be binary (0/1), found values: ",
           paste(utils::head(unique_vals, 10), collapse = ", "))
    }
  } else {
    stop("Outcome '", outcome, "' must be numeric (0/1), factor, or logical, not ",
         class(y)[1])
  }

  # Remove NAs in outcome
  n_na <- sum(is.na(data[[outcome]]))
  if (n_na > 0) {
    warning(n_na, " NA values in outcome '", outcome, "' removed")
    data <- data[!is.na(data[[outcome]]), ]
  }

  # Check for constant outcome (all 0 or all 1)
  unique_y <- unique(data[[outcome]])
  if (length(unique_y) < 2) {
    stop("Outcome '", outcome, "' is constant (all ",
         unique_y[1], "). Need both 0 and 1 values for classification.",
         call. = FALSE)
  }

  data
}

#' Validate and convert attributes to factors
#'
#' @keywords internal
#'
#' @param data A data frame
#' @param attributes Character vector of attribute column names
#' @return Data frame with all attributes as factors (unused levels dropped)
#' @noRd
.validate_attributes <- function(data, attributes) {
  for (attr_name in attributes) {
    col <- data[[attr_name]]

    if (!is.factor(col)) {
      data[[attr_name]] <- as.factor(col)
    }

    # Drop unused levels
    data[[attr_name]] <- droplevels(data[[attr_name]])

    # Warn about single-level factors
    n_lvls <- nlevels(data[[attr_name]])
    if (n_lvls < 2) {
      warning("Attribute '", attr_name, "' has only ", n_lvls,
              " level(s) and will not contribute to the model")
    }
  }

  data
}

#' Create dummy variables and attribute map
#'
#' @keywords internal
#'
#' @param data A data frame with factor attributes
#' @param outcome Character name of outcome column
#' @param attributes Character vector of attribute column names
#' @return Named list with `dummy_data` (data.frame) and `attr_map` (tibble)
#' @noRd
.make_dummies <- function(data, outcome, attributes) {
  # No-intercept formula + identity contrasts = full dummy coding (all levels)
  dummy_formula <- stats::as.formula(
    paste("~", paste(attributes, collapse = " + "), "- 1")
  )

  # Force all levels to be included (default contrasts drop reference levels)
  contrasts_list <- lapply(data[attributes], function(x) {
    stats::contr.treatment(levels(x), contrasts = FALSE)
  })

  dummy_mat <- stats::model.matrix(dummy_formula, data = data,
                                   contrasts.arg = contrasts_list)
  raw_names <- colnames(dummy_mat)
  clean_names <- make.names(raw_names, unique = TRUE)
  colnames(dummy_mat) <- clean_names

  # Build attribute map using exact matching (avoids prefix collisions)
  attr_map <- .create_attr_map(raw_names, clean_names, data, attributes)

  # Combine outcome with dummies
  dummy_data <- data.frame(
    .outcome = data[[outcome]],
    dummy_mat,
    check.names = FALSE
  )

  list(dummy_data = dummy_data, attr_map = attr_map)
}

#' Map dummy column names to original attributes and levels
#'
#' @keywords internal
#'
#' Uses exact matching on raw model.matrix column names (before make.names)
#' to avoid ambiguity when attribute names are prefixes of each other
#' (e.g., "Job" vs "JobPlans").
#'
#' @param raw_names Character vector of raw column names from model.matrix
#' @param clean_names Character vector of clean names (after make.names)
#' @param data Data frame with factor attributes
#' @param attributes Character vector of attribute names
#' @return A tibble with columns: var_name, attribute, level
#' @noRd
.create_attr_map <- function(raw_names, clean_names, data, attributes) {
  n <- length(clean_names)
  attr_col <- character(n)
  level_col <- character(n)

  for (attr_name in attributes) {
    lvls <- levels(data[[attr_name]])
    for (lvl in lvls) {
      expected_raw <- paste0(attr_name, lvl)
      idx <- which(raw_names == expected_raw)
      if (length(idx) == 1) {
        attr_col[idx] <- attr_name
        level_col[idx] <- lvl
      }
    }
  }

  # Check for unmapped columns
  unmapped <- which(attr_col == "")
  if (length(unmapped) > 0) {
    warning("Could not map ", length(unmapped), " dummy columns: ",
            paste(clean_names[unmapped], collapse = ", "))
    attr_col[unmapped] <- NA_character_
    level_col[unmapped] <- NA_character_
  }

  tibble::tibble(
    var_name = clean_names,
    attribute = attr_col,
    level = level_col
  )
}

#' Prepare data for level-specific model fitting (dummy-coded)
#'
#' @keywords internal
#'
#' Orchestrates formula parsing, validation, dummy coding, and attribute mapping.
#'
#' @param formula A formula
#' @param data A data frame
#' @return Named list with: dummy_data, outcome, attributes, attr_map,
#'   n_obs, n_levels, formula
#' @noRd
.prepare_data <- function(formula, data) {
  parsed <- .parse_formula(formula, data)
  data <- .validate_outcome(data, parsed$outcome)
  data <- .validate_attributes(data, parsed$attributes)

  result <- .make_dummies(data, parsed$outcome, parsed$attributes)

  list(
    dummy_data = result$dummy_data,
    outcome    = parsed$outcome,
    attributes = parsed$attributes,
    attr_map   = result$attr_map,
    n_obs      = nrow(data),
    n_levels   = nrow(result$attr_map),
    formula    = formula
  )
}

#' Prepare data for attribute-level model fitting (factors passed directly)
#'
#' @keywords internal
#'
#' Validates outcome and attributes but skips dummy coding.
#'
#' @param formula A formula
#' @param data A data frame
#' @return Named list with: data, outcome, attributes, n_obs, formula
#' @noRd
.prepare_data_attributes <- function(formula, data) {
  parsed <- .parse_formula(formula, data)
  data <- .validate_outcome(data, parsed$outcome)
  data <- .validate_attributes(data, parsed$attributes)

  list(
    data       = data,
    outcome    = parsed$outcome,
    attributes = parsed$attributes,
    n_obs      = nrow(data),
    formula    = formula
  )
}
