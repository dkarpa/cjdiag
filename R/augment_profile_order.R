# ---- Profile Order Augmentation Utility ----

#' Augment Data with Swapped Profile Order
#'
#' Doubles the dataset by swapping left/right profiles and inverting the outcome.
#' This satisfies the profile order constraint required for valid CRT hypothesis
#' testing with HierNet. Apply this BEFORE calling [cj_fit()] with
#' `method = "crt"`.
#'
#' @param data A data frame containing conjoint data.
#' @param outcome Character name of the binary outcome column (0/1).
#' @param left Character vector of column names for the left profile attributes.
#' @param right Character vector of column names for the right profile attributes.
#'   Must be the same length as `left`.
#'
#' @return A data frame with `2 * nrow(data)` rows: the original data followed
#'   by the swapped copy (left/right exchanged, outcome inverted).
#'
#' @export
#'
#' @examples
#' \donttest{
#' df <- data.frame(
#'   y = sample(0:1, 100, TRUE),
#'   left_a = factor(sample(c("x","y"), 100, TRUE)),
#'   left_b = factor(sample(c("p","q"), 100, TRUE)),
#'   right_a = factor(sample(c("x","y"), 100, TRUE)),
#'   right_b = factor(sample(c("p","q"), 100, TRUE))
#' )
#' augmented <- augment_profile_order(df, "y",
#'   left = c("left_a", "left_b"), right = c("right_a", "right_b"))
#' nrow(augmented)  # doubled
#' }
augment_profile_order <- function(data, outcome, left, right) {

  if (!is.data.frame(data)) {
    stop("`data` must be a data frame", call. = FALSE)
  }
  if (length(left) != length(right)) {
    stop("`left` and `right` must have the same length", call. = FALSE)
  }
  if (!outcome %in% names(data)) {
    stop("Outcome '", outcome, "' not found in data", call. = FALSE)
  }

  missing <- setdiff(c(left, right), names(data))
  if (length(missing) > 0) {
    stop("Columns not found in data: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }

  # Create swapped copy
  swapped <- data

  for (i in seq_along(left)) {
    swapped[[left[i]]] <- data[[right[i]]]
    swapped[[right[i]]] <- data[[left[i]]]
  }

  # Invert outcome
  swapped[[outcome]] <- 1 - data[[outcome]]

  rbind(data, swapped)
}
