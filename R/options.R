# ---- Global Options System for cjdiag ----
#
# Follows the fixest/data.table pattern: package-level environment
# with set/get functions. Options are NOT stored in base::options().

# Package environment for storing options
.cjdiag_env <- new.env(parent = emptyenv())

# Default values
.cjdiag_defaults <- list(
  base_size = 12,
  palette = "default",
  font_family = "",
  label_wrap = 35L,
  theme = NULL,
  print_n = 10L,
  labels = list(
    attribute.names = NULL,
    level.names = NULL
  )
)


#' Set Global Plot Theme Options
#'
#' Configure default plotting options for all cjdiag plots. These
#' serve as the middle-priority layer: explicit function arguments override
#' these, and these override the hardcoded package defaults.
#'
#' Calling with no arguments resets all options to defaults.
#'
#' @param base_size Default font size for plots (default 12)
#' @param palette Default color palette: `"default"`, `"colorblind"`, or `"grey"` (default `"default"`)
#' @param font_family Default font family (default `""`)
#' @param label_wrap Default character width for label wrapping (default 35)
#' @param theme A complete [ggplot2::theme()] object to use as default (default `NULL`, uses [theme_cjdiag()])
#' @param print_n Default number of rows shown by `print()` methods (default 10)
#'
#' @return Invisibly returns the previous options (for save/restore pattern)
#' @family customization
#' @export
#'
#' @examples
#' # Set colorblind-friendly defaults
#' old <- set_cjdiag_theme(palette = "colorblind", base_size = 14)
#'
#' # Reset to defaults
#' set_cjdiag_theme()
#'
#' # Restore previous options
#' \dontrun{
#' do.call(set_cjdiag_theme, old)
#' }
set_cjdiag_theme <- function(base_size = 12, palette = "default",
                              font_family = "", label_wrap = 35L,
                              theme = NULL, print_n = 10L) {
  palette <- match.arg(palette, c("default", "colorblind", "grey"))
  stopifnot(is.numeric(base_size), base_size > 0)
  stopifnot(is.numeric(label_wrap), label_wrap > 0)
  stopifnot(is.numeric(print_n), print_n > 0)

  prev <- .cjdiag_env$options

  .cjdiag_env$options <- list(
    base_size = base_size,
    palette = palette,
    font_family = font_family,
    label_wrap = as.integer(label_wrap),
    theme = theme,
    print_n = as.integer(print_n),
    labels = .cjdiag_env$options$labels %||% .cjdiag_defaults$labels
  )

  invisible(prev)
}


#' Set Global Label Dictionary
#'
#' Configure a label dictionary for renaming attributes and levels in
#' all cjdiag plot and print output. Inspired by [fixest::setFixest_dict()].
#'
#' @param attribute.names Named character vector mapping original attribute names
#'   to display names, e.g., `c(LanguageSkills = "English Proficiency")`
#' @param level.names Named list of named character vectors for level renaming,
#'   e.g., `list(Gender = c(female = "Female", male = "Male"))`
#' @param reset If `TRUE`, clears the label dictionary (default `FALSE`)
#'
#' @return Invisibly returns the previous labels
#' @family customization
#' @export
#'
#' @examples
#' set_cjdiag_labels(
#'   attribute.names = c(LanguageSkills = "English Proficiency",
#'                       JobPlans = "Plans for Employment")
#' )
#'
#' # Reset
#' set_cjdiag_labels(reset = TRUE)
set_cjdiag_labels <- function(attribute.names = NULL, level.names = NULL,
                               reset = FALSE) {
  prev <- .cjdiag_env$options$labels

  if (reset) {
    .cjdiag_env$options$labels <- list(
      attribute.names = NULL,
      level.names = NULL
    )
  } else {
    # Merge with existing labels
    current <- .cjdiag_env$options$labels %||% list()
    if (!is.null(attribute.names)) {
      existing <- current$attribute.names %||% character(0)
      merged <- c(existing, attribute.names)
      # Later entries win for duplicates
      merged <- merged[!duplicated(names(merged), fromLast = TRUE)]
      current$attribute.names <- merged
    }
    if (!is.null(level.names)) {
      existing <- current$level.names %||% list()
      for (attr_name in names(level.names)) {
        existing[[attr_name]] <- c(
          existing[[attr_name]] %||% character(0),
          level.names[[attr_name]]
        )
        # Dedup
        existing[[attr_name]] <- existing[[attr_name]][
          !duplicated(names(existing[[attr_name]]), fromLast = TRUE)
        ]
      }
      current$level.names <- existing
    }
    .cjdiag_env$options$labels <- current
  }

  invisible(prev)
}


#' Get Global cjdiag Options
#'
#' @param what Optional: name of a specific option to retrieve (e.g., `"base_size"`,
#'   `"palette"`, `"labels"`). If `NULL`, returns all options.
#'
#' @return The requested option value, or a list of all options
#' @family customization
#' @export
#'
#' @examples
#' get_cjdiag_options()
#' get_cjdiag_options("palette")
get_cjdiag_options <- function(what = NULL) {
  opts <- .cjdiag_env$options %||% .cjdiag_defaults

  if (is.null(what)) return(opts)
  opts[[what]]
}


# Initialize options on package load
.onLoad <- function(libname, pkgname) {
  .cjdiag_env$options <- .cjdiag_defaults

  # Conditionally register broom methods if generics + vctrs available.
  # vctrs::s3_register is the standard mechanism for delayed S3 registration
  # (used by tidyverse packages). generics provides the tidy/glance generics.
  # No glance.cjdiag_importance is registered because importance objects

  # don't have model-level summaries.
  tryCatch({
    if (requireNamespace("generics", quietly = TRUE) &&
        requireNamespace("vctrs", quietly = TRUE)) {
      s3_register <- vctrs::s3_register
      s3_register("generics::tidy", "cjdiag_fit")
      s3_register("generics::glance", "cjdiag_fit")
      s3_register("generics::tidy", "cjdiag_importance")
    }
  }, error = function(e) NULL)  # silently skip if registration fails

  invisible()
}
