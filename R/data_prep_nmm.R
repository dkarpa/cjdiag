# ---- Data Preparation for Nested Marginal Means ----
#
# Internal function for preparing conjoint data in the format required
# by the Nested Marginal Means (NMM) algorithm. Unlike .prepare_data(),
# this creates level dummies manually (not via model.matrix), adds
# ambiguity indicators per attribute per task, and identifies resp_pair
# groupings.

#' Helper to clean level names for dummy column naming
#'
#' @keywords internal
#'
#' Removes non-alphanumeric characters and lowercases.
#'
#' @param x Character string
#' @return Cleaned character string
#' @noRd
.clean_name <- function(x) {
  tolower(gsub("[^a-zA-Z0-9]", "", x))
}

#' Detect or create task identifier column within respondent groups
#'
#' @keywords internal
#'
#' Looks for common task column names (contest_no, task, round, pair,
#' task_id, task_number). If none found, infers tasks by grouping
#' consecutive row pairs within each respondent.
#'
#' @param data A data frame
#' @param resp_id Character name of respondent ID column
#' @return A list with `data` (augmented with `.task_id` column) and
#'   `task_col` (the name of the detected or created task column)
#' @noRd
.detect_task_column <- function(data, resp_id) {
  candidate_names <- c("contest_no", "task", "round", "pair",
                        "task_id", "task_number")
  found <- intersect(candidate_names, names(data))

  if (length(found) > 0) {
    task_col <- found[1]
    data[[".task_id"]] <- data[[task_col]]
  } else {
    # Infer task IDs: every 2 consecutive rows within a respondent = 1 task
    data <- data %>%
      dplyr::group_by(.data[[resp_id]]) %>%
      dplyr::mutate(.task_id = ceiling(dplyr::row_number() / 2)) %>%
      dplyr::ungroup()
    task_col <- NULL
  }

  list(data = data, task_col = task_col)
}

#' Generate unique short prefixes for attribute names
#'
#' @keywords internal
#'
#' Starts with first 4 characters (lowercased). If duplicates exist,
#' tries 6 characters, then falls back to the full attribute name.
#'
#' @param attributes Character vector of attribute names
#' @return Named character vector (attribute -> prefix)
#' @noRd
.make_attr_prefixes <- function(attributes) {
  prefixes <- stats::setNames(tolower(substr(attributes, 1, 4)), attributes)

  # Check for duplicates
  if (anyDuplicated(prefixes)) {
    duped <- duplicated(prefixes) | duplicated(prefixes, fromLast = TRUE)
    prefixes[duped] <- tolower(substr(attributes[duped], 1, 6))
  }

  # Still duplicated? Use full name

  if (anyDuplicated(prefixes)) {
    duped <- duplicated(prefixes) | duplicated(prefixes, fromLast = TRUE)
    prefixes[duped] <- tolower(attributes[duped])
  }

  prefixes
}

#' Prepare data for Nested Marginal Means analysis
#'
#' @keywords internal
#'
#' Orchestrates formula parsing, validation, task detection, ambiguity
#' indicator creation, and manual level dummy coding for the NMM method.
#'
#' @param formula A formula of the form `outcome ~ attr1 + attr2 + ...`
#' @param data A data frame in long format (one row per profile)
#' @param resp_id Character string naming the respondent ID column
#' @return Named list with: data, outcome, attributes, attr_map,
#'   var_labels, all_vars, resp_id, n_obs, n_levels, formula
#' @noRd
.prepare_data_nmm <- function(formula, data, resp_id) {


  # --- 1. Parse formula ----
  parsed <- .parse_formula(formula, data)
  outcome <- parsed$outcome
  attributes <- parsed$attributes

  # --- 2. Validate resp_id ----
  if (!is.character(resp_id) || length(resp_id) != 1) {
    stop("`resp_id` must be a single character string")
  }
  if (!resp_id %in% names(data)) {
    stop("Respondent ID column '", resp_id, "' not found in data")
  }

  # --- 3. Validate outcome (binary 0/1) ----
  data <- .validate_outcome(data, outcome)

  # --- 4. Convert attributes to factors ----
  data <- .validate_attributes(data, attributes)

  # --- 5. Detect or create task identifier ----
  task_info <- .detect_task_column(data, resp_id)
  data <- task_info$data

  # Create resp_pair identifier
  data$resp_pair <- paste0(data[[resp_id]], "_", data$.task_id)

  # Validate that all pairs have exactly 2 rows
  pair_sizes <- table(data$resp_pair)
  bad_pairs <- pair_sizes[pair_sizes != 2]
  if (length(bad_pairs) > 0) {
    warning(length(bad_pairs), " choice task(s) do not have exactly 2 profiles. ",
            "These will be removed.")
    valid_pairs <- names(pair_sizes[pair_sizes == 2])
    data <- data[data$resp_pair %in% valid_pairs, ]
  }

  # --- 6. Create ambiguity indicators ----
  # For each task, check if both profiles share the same attribute level
  # Vectorized: add row number within pair, pivot wide, compare, merge back
  data <- data %>%
    dplyr::group_by(resp_pair) %>%
    dplyr::mutate(.profile_idx = dplyr::row_number()) %>%
    dplyr::ungroup()

  # Split into profile 1 and profile 2
  p1 <- data[data$.profile_idx == 1, c("resp_pair", attributes), drop = FALSE]
  p2 <- data[data$.profile_idx == 2, c("resp_pair", attributes), drop = FALSE]

  # Match by resp_pair
  p_merged <- dplyr::inner_join(p1, p2, by = "resp_pair", suffix = c("_p1", "_p2"))

  # Compute ambiguity for each attribute
  for (attr_name in attributes) {
    col1 <- paste0(attr_name, "_p1")
    col2 <- paste0(attr_name, "_p2")
    p_merged[[paste0(attr_name, "_amb")]] <- as.integer(
      as.character(p_merged[[col1]]) == as.character(p_merged[[col2]])
    )
  }

  amb_cols <- paste0(attributes, "_amb")
  amb_df <- p_merged[, c("resp_pair", amb_cols), drop = FALSE]
  data <- dplyr::left_join(data, amb_df, by = "resp_pair")
  data$.profile_idx <- NULL

  # --- 7. Create level dummies ----
  prefixes <- .make_attr_prefixes(attributes)

  attr_map <- character(0)   # named vector: var_name -> attribute

  var_labels <- list()        # named list: var_name -> "Attribute: Level"
  all_vars <- character(0)

  for (attr_name in attributes) {
    lvls <- levels(data[[attr_name]])
    prefix <- prefixes[[attr_name]]

    for (lvl in lvls) {
      var_name <- paste0(prefix, "_", .clean_name(lvl))

      # Handle potential duplicate var_names across attributes
      if (var_name %in% all_vars) {
        var_name <- paste0(tolower(.clean_name(attr_name)), "_", .clean_name(lvl))
      }

      data[[var_name]] <- as.integer(data[[attr_name]] == lvl)
      attr_map[var_name] <- attr_name
      var_labels[[var_name]] <- paste0(attr_name, ": ", lvl)
      all_vars <- c(all_vars, var_name)
    }
  }

  # --- 8. Clean up temporary columns ----
  data$.task_id <- NULL

  # --- 9. Return ----
  list(
    data       = data,
    outcome    = outcome,
    attributes = attributes,
    attr_map   = attr_map,
    var_labels = var_labels,
    all_vars   = all_vars,
    resp_id    = resp_id,
    n_obs      = nrow(data),
    n_levels   = length(all_vars),
    formula    = formula
  )
}
