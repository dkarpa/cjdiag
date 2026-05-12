# ---- Theme, Palette, and Plot Options System ----

#' Custom ggplot2 Theme for cjdiag
#'
#' A publication-ready theme based on [ggplot2::theme_minimal()] with consistent
#' defaults used across all cjdiag plots. Removes minor gridlines, controls
#' major gridlines, and positions the legend at top.
#'
#' @param base_size Base font size (default 12)
#' @param base_family Base font family (default `""`)
#' @param grid_y Show horizontal gridlines (default `FALSE`)
#' @param grid_x Show vertical gridlines (default `TRUE`)
#'
#' @return A [ggplot2::theme()] object
#' @family customization
#' @export
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_cjdiag()
theme_cjdiag <- function(base_size = 12, base_family = "", grid_y = FALSE,
                         grid_x = TRUE) {
  th <- ggplot2::theme_minimal(base_size = base_size, base_family = base_family)
  th <- th + ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    legend.position = "top"
  )
  if (!grid_y) {
    th <- th + ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank()
    )
  }
  if (!grid_x) {
    th <- th + ggplot2::theme(
      panel.grid.major.x = ggplot2::element_blank()
    )
  }
  th
}


#' Color Palettes for cjdiag Plots
#'
#' Returns a named character vector of colors for use in cjdiag plots.
#'
#' @param palette Palette name: `"default"`, `"colorblind"` (Okabe-Ito), or `"grey"`
#' @param n Number of colors (currently ignored; always returns 3)
#'
#' @return Named character vector with elements `primary`, `secondary`, `tertiary`
#' @family customization
#' @export
#'
#' @examples
#' cjdiag_palette("default")
#' cjdiag_palette("colorblind")
cjdiag_palette <- function(palette = "default", n = 3) {
  palette <- match.arg(palette, c("default", "colorblind", "grey"))
  switch(palette,
    "default" = c(primary = "#2171b5", secondary = "#d62728",
                  tertiary = "#d3d3d3"),
    "colorblind" = c(primary = "#0072B2", secondary = "#D55E00",
                     tertiary = "#999999"),
    "grey" = c(primary = "#525252", secondary = "#969696",
               tertiary = "#d9d9d9")
  )
}


#' Resolve Plot Options (internal)
#'
#' Three-tier priority: explicit arg > global options > hardcoded default.
#'
#' @param base_size Numeric or NULL
#' @param colors Named character vector or NULL
#' @param palette Palette name or NULL
#' @param theme ggplot2 theme object or NULL
#' @param label_wrap Integer label wrap width or NULL
#' @param attribute.names Named character vector for relabeling attributes
#' @param level.names Named list for relabeling levels
#' @param ... Extra arguments (currently unused, reserved for future extensions)
#' @return List with: base_size, colors, theme, label_wrap, attribute.names, level.names
#' @keywords internal
#' @noRd
.resolve_plot_options <- function(base_size = NULL, colors = NULL,
                                  palette = NULL, theme = NULL,
                                  label_wrap = NULL,
                                  attribute.names = NULL,
                                  level.names = NULL, ...) {
  # Get global options (may be NULL if not set)
  globals <- tryCatch(get_cjdiag_options(), error = function(e) list())

  # Resolve base_size
  bs <- base_size %||% globals$base_size %||% 12

  # Resolve palette/colors
  pal_name <- palette %||% globals$palette %||% "default"
  default_colors <- cjdiag_palette(pal_name)
  if (!is.null(colors)) {
    # Merge explicit colors over defaults
    merged <- default_colors
    merged[names(colors)] <- colors
    clrs <- merged
  } else {
    clrs <- default_colors
  }

  # Resolve theme
  if (!is.null(theme)) {
    th <- theme
  } else if (!is.null(globals$theme)) {
    th <- globals$theme
  } else {
    font_family <- globals$font_family %||% ""
    th <- theme_cjdiag(base_size = bs, base_family = font_family)
  }

  # Resolve label_wrap
  lw <- label_wrap %||% globals$label_wrap %||% 35L

  # Resolve labels: explicit > global dictionary > NULL
  global_labels <- globals$labels %||% list()
  a_names <- attribute.names %||% global_labels$attribute.names
  l_names <- level.names %||% global_labels$level.names

  list(
    base_size = bs,
    colors = clrs,
    theme = th,
    label_wrap = as.integer(lw),
    attribute.names = a_names,
    level.names = l_names
  )
}


#' Apply Label Remapping to Plot Data (internal)
#'
#' Renames attribute and level values in a data frame using the
#' label dictionaries from explicit arguments or global options.
#'
#' @param data Data frame with `attribute` and optionally `level` columns
#' @param opts Options list from `.resolve_plot_options()`
#' @return Modified data frame with relabeled values
#' @keywords internal
#' @noRd
.apply_labels <- function(data, opts) {
  # Rename levels FIRST (before attributes change), using original attribute names
  if (!is.null(opts$level.names) && "level" %in% names(data)) {
    for (attr_name in names(opts$level.names)) {
      level_map <- opts$level.names[[attr_name]]
      for (old_lev in names(level_map)) {
        mask <- data$attribute == attr_name & data$level == old_lev
        data$level[mask] <- level_map[[old_lev]]
      }
    }
  }

  # Then rename attributes
  if (!is.null(opts$attribute.names) && "attribute" %in% names(data)) {
    for (old in names(opts$attribute.names)) {
      data$attribute[data$attribute == old] <- opts$attribute.names[[old]]
    }
  }

  data
}
