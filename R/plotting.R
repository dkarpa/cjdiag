# ---- Plot Methods for Conjoint Diagnostic Objects ----

# Common plot parameters documented once, referenced by all methods
# @param base_size Font size (default from global options or 12)
# @param colors Named character vector overriding specific palette colors
# @param palette Palette name: "default", "colorblind", "grey"
# @param theme A ggplot2 theme object (complete override)
# @param label_wrap Character width for label wrapping (default 35)
# @param attribute.names Named character vector renaming attributes in display
# @param level.names Named list of named character vectors for level renaming
# @param group_by_attribute If TRUE, group levels by attribute with visual separators
# @param ... Additional arguments passed to primary ggplot2 geom

#' Plot Random Forest Results
#'
#' @param x A `cjdiag_forest` object from [cj_fit()]
#' @param type Plot type: `"importance"` (default), `"combined"`, `"rank"`,
#'   `"cumulative"` (MDA rank-decay with labels), or `"cumulative_pct"`
#'   (cumulative % of total MDA, area chart like NMM cumulative)
#' @param top_n Number of levels to display (default 25; NULL = all levels).
#'   For `"cumulative"`, defaults to all levels if not specified.
#' @param base_size Font size (default from global options or 12)
#' @param colors Named character vector overriding specific palette colors
#' @param palette Palette name: `"default"`, `"colorblind"`, or `"grey"`
#' @param theme A complete [ggplot2::theme()] object (overrides all theme defaults)
#' @param label_wrap Character width for label wrapping (default 35)
#' @param attribute.names Named character vector renaming attributes in display
#' @param level.names Named list for renaming levels
#' @param group_by_attribute Group levels by attribute with visual separators (default `FALSE`)
#' @param ... Additional arguments passed to primary ggplot2 geom
#'
#' @return A ggplot object
#' @family plotting
#' @examples
#' \donttest{
#' df <- data.frame(
#'   y = sample(0:1, 200, TRUE),
#'   a = factor(sample(c("x","y"), 200, TRUE)),
#'   b = factor(sample(c("p","q","r"), 200, TRUE))
#' )
#' rf <- cj_fit(y ~ a + b, data = df, method = "forest")
#' plot(rf)
#' plot(rf, palette = "colorblind", base_size = 14)
#' plot(rf, type = "combined")
#' }
#' @export
plot.cjdiag_forest <- function(x, type = "importance", top_n = NULL,
                               base_size = NULL, colors = NULL, palette = NULL,
                               theme = NULL, label_wrap = NULL,
                               attribute.names = NULL, level.names = NULL,
                               group_by_attribute = FALSE, ...) {
  type <- match.arg(type, c("importance", "combined", "rank", "cumulative",
                            "cumulative_pct"))
  opts <- .resolve_plot_options(base_size = base_size, colors = colors,
                                palette = palette, theme = theme,
                                label_wrap = label_wrap,
                                attribute.names = attribute.names,
                                level.names = level.names, ...)

  if (is.null(top_n) && !type %in% c("cumulative", "cumulative_pct")) top_n <- 25L

  if (type == "importance") {
    .plot_importance(x$results, top_n, metric = "mda", opts = opts,
                     group_by_attribute = group_by_attribute)
  } else if (type == "combined") {
    .plot_combined(x$results, top_n, opts = opts)
  } else if (type == "cumulative") {
    .plot_cumulative(x$results, top_n, opts = opts)
  } else if (type == "cumulative_pct") {
    .plot_cumulative_pct(x$results, top_n, opts = opts)
  } else {
    .plot_rank(x$results, top_n, opts = opts)
  }
}

#' Plot Decision Tree
#'
#' Renders the decision tree using [rpart.plot::rpart.plot()].
#'
#' @param x A `cjdiag_tree` object from [cj_fit()]
#' @param ... Additional arguments passed to [rpart.plot::rpart.plot()]
#'
#' @return Invisible NULL (called for side effect of plotting)
#' @examples
#' \donttest{
#' df <- data.frame(
#'   y = sample(0:1, 200, TRUE),
#'   a = factor(sample(c("x","y"), 200, TRUE)),
#'   b = factor(sample(c("p","q","r"), 200, TRUE))
#' )
#' tr <- cj_fit(y ~ a + b, data = df, method = "tree")
#' plot(tr)
#' }
#' @family plotting
#' @export
plot.cjdiag_tree <- function(x, ...) {

  if (!requireNamespace("rpart.plot", quietly = TRUE)) {
    stop("Package 'rpart.plot' is required for tree visualization. ",
         "Install it with: install.packages('rpart.plot')",
         call. = FALSE)
  }

  user_args <- list(...)

  # Pretty split labels: replace dummy column names (e.g.
  # "JobPlansno.plans.to.look.for.work") with "Attribute: level" form.
  # Only applies to dummy-coded (level-resolution) trees that carry an
  # attr_map; attribute-level trees use raw attribute names already.
  if (!is.null(x$attr_map) && nrow(x$attr_map) > 0 &&
      is.null(user_args$split.fun)) {
    am <- x$attr_map[!is.na(x$attr_map$attribute), , drop = FALSE]
    # Match longest var_name first so prefix collisions are resolved correctly.
    o <- order(nchar(am$var_name), decreasing = TRUE)
    var_names <- am$var_name[o]
    pretty    <- paste0(am$attribute[o], ": ", am$level[o])

    user_args$split.fun <- function(x, labs, digits, varlen, faclen) {
      vapply(labs, function(lab) {
        for (i in seq_along(var_names)) {
          vn <- var_names[i]
          if (startsWith(lab, vn)) {
            return(paste0(pretty[i], substring(lab, nchar(vn) + 1L)))
          }
        }
        lab
      }, character(1), USE.NAMES = FALSE)
    }
  }

  defaults <- list(
    x = x$model,
    type = 4, extra = 101, under = TRUE, fallen.leaves = TRUE,
    box.palette = "BuOr", shadow.col = "gray70",
    main = "", cex = 0.9, roundint = FALSE, varlen = 0
  )
  do.call(rpart.plot::rpart.plot, utils::modifyList(defaults, user_args))

  invisible(NULL)
}

#' Plot CRT/HierNet Results
#'
#' @param x A `cjdiag_crt` object from [cj_fit()]
#' @param type Plot type: `"robustness"` (default), `"survival"`, `"rank"`,
#'   `"mda"`, or `"cv"`. `"rank"` is a connected-dot plot of each level's
#'   survival statistic (max \eqn{\lambda} at which the coefficient is
#'   nonzero), ordered from most to least attended.
#' @param top_n Number of levels to display. Default `25` for `"robustness"`,
#'   `"mda"`, `"rank"`, and `"survival"`. Pass `NULL` to show every level.
#' @inheritParams plot.cjdiag_forest
#'
#' @return A ggplot object
#' @examples
#' \donttest{
#' # CRT requires the hierNet package
#' if (requireNamespace("hierNet", quietly = TRUE)) {
#'   df <- data.frame(
#'     y = sample(0:1, 200, TRUE),
#'     a = factor(sample(c("x","y"), 200, TRUE)),
#'     b = factor(sample(c("p","q","r"), 200, TRUE))
#'   )
#'   crt <- cj_fit(y ~ a + b, data = df, method = "crt",
#'                  lambda_grid = c(5, 10), n_folds = 2, n_perm = 2)
#'   plot(crt, type = "robustness")
#' }
#' }
#' @family plotting
#' @export
plot.cjdiag_crt <- function(x, type = "robustness", top_n = 25L,
                            base_size = NULL, colors = NULL, palette = NULL,
                            theme = NULL, label_wrap = NULL,
                            attribute.names = NULL, level.names = NULL, ...) {
  type <- match.arg(type, c("robustness", "survival", "rank", "mda", "cv"))
  opts <- .resolve_plot_options(base_size = base_size, colors = colors,
                                palette = palette, theme = theme,
                                label_wrap = label_wrap,
                                attribute.names = attribute.names,
                                level.names = level.names, ...)

  if (type == "robustness") {
    .plot_crt_robustness(x$results, top_n, opts = opts)
  } else if (type == "survival") {
    .plot_crt_survival(x$results, x$path_coefs, x$lambda_grid, top_n, opts = opts)
  } else if (type == "rank") {
    .plot_crt_rank(x$results, top_n, opts = opts)
  } else if (type == "mda") {
    .plot_importance(x$results, top_n, metric = "mda", opts = opts)
  } else {
    .plot_crt_cv(x$cv_results, x$optimal_lambda, x$lambda_1se, opts = opts)
  }
}

#' Plot Importance Results
#'
#' @param x A `cjdiag_importance` object from [importance()]
#' @param type Plot type: `"mda"` (default), `"root"`, `"combined"`, `"cumulative"`,
#'   or `"cumulative_pct"` (forest only). For `nmm` objects, only `"mda"` and
#'   `"cumulative"` are valid.
#' @param top_n Number of items to display (default 25; NULL = all levels).
#' @inheritParams plot.cjdiag_forest
#'
#' @return A ggplot object
#' @examples
#' \donttest{
#' df <- data.frame(
#'   y = sample(0:1, 200, TRUE),
#'   a = factor(sample(c("x","y"), 200, TRUE)),
#'   b = factor(sample(c("p","q","r"), 200, TRUE))
#' )
#' rf <- cj_fit(y ~ a + b, data = df, method = "forest")
#' imp <- importance(rf)
#' plot(imp)
#' }
#' @family plotting
#' @export
plot.cjdiag_importance <- function(x, type = "mda", top_n = NULL,
                                   base_size = NULL, colors = NULL,
                                   palette = NULL, theme = NULL,
                                   label_wrap = NULL,
                                   attribute.names = NULL,
                                   level.names = NULL, ...) {
  opts <- .resolve_plot_options(base_size = base_size, colors = colors,
                                palette = palette, theme = theme,
                                label_wrap = label_wrap,
                                attribute.names = attribute.names,
                                level.names = level.names, ...)

  if (x$method == "nmm") {
    type <- match.arg(type, c("mda", "cumulative"))
  } else {
    type <- match.arg(type, c("mda", "root", "combined", "cumulative",
                              "cumulative_pct"))
  }

  if (is.null(top_n) && !type %in% c("cumulative", "cumulative_pct")) top_n <- 25L

  if (type == "mda") {
    if (x$method == "forest" || x$method == "crt") {
      .plot_importance(x$results, top_n, metric = "mda", opts = opts)
    } else if (x$method == "nmm") {
      .plot_importance(x$results, top_n, metric = "mm", opts = opts)
    } else {
      .plot_importance(x$results, top_n, metric = "importance", opts = opts)
    }
  } else if (type == "root") {
    if (x$method != "forest") {
      stop("Plot type 'root' is only available for forest models. ",
           "Valid types for ", x$method, ": 'mda'",
           if (x$method == "nmm") ", 'cumulative'" else "",
           call. = FALSE)
    }
    .plot_importance(x$results, top_n, metric = "root_pct", opts = opts)
  } else if (type == "cumulative") {
    if (x$method == "nmm") {
      return(.plot_nmm_cumulative(x$results, top_n, opts = opts))
    }
    if (x$method != "forest") {
      stop("Plot type 'cumulative' is only available for forest and nmm models. ",
           "Valid types for ", x$method, ": 'mda'", call. = FALSE)
    }
    .plot_cumulative(x$results, top_n, opts = opts)
  } else if (type == "cumulative_pct") {
    if (x$method != "forest") {
      stop("Plot type 'cumulative_pct' is only available for forest models. ",
           "Valid types for ", x$method, ": 'mda'", call. = FALSE)
    }
    .plot_cumulative_pct(x$results, top_n, opts = opts)
  } else {
    if (x$method != "forest") {
      stop("Plot type 'combined' is only available for forest models. ",
           "Valid types for ", x$method, ": 'mda'", call. = FALSE)
    }
    .plot_combined(x$results, top_n, opts = opts)
  }
}


#' Plot Nested Marginal Means Results
#'
#' Plots the cumulative percentage of choices explained by the top
#' attribute levels in order of decisiveness.
#'
#' @param x A `cjdiag_nmm` object from [cj_fit()]
#' @param top_n Number of levels to display (default 25; NULL = all).
#' @inheritParams plot.cjdiag_forest
#'
#' @return A ggplot object
#' @examples
#' \donttest{
#' df <- data.frame(
#'   y = sample(0:1, 200, TRUE),
#'   a = factor(sample(c("x","y"), 200, TRUE)),
#'   b = factor(sample(c("p","q","r"), 200, TRUE)),
#'   id = rep(1:100, each = 2)
#' )
#' nmm <- cj_fit(y ~ a + b, data = df, method = "nmm", resp_id = "id", n_boot = 0)
#' plot(nmm)
#' }
#' @family plotting
#' @export
plot.cjdiag_nmm <- function(x, top_n = NULL,
                            base_size = NULL, colors = NULL, palette = NULL,
                            theme = NULL, label_wrap = NULL,
                            attribute.names = NULL, level.names = NULL, ...) {
  opts <- .resolve_plot_options(base_size = base_size, colors = colors,
                                palette = palette, theme = theme,
                                label_wrap = label_wrap,
                                attribute.names = attribute.names,
                                level.names = level.names, ...)

  if (is.null(top_n)) top_n <- 25L

  .plot_nmm_cumulative(x$results, top_n, opts = opts)
}


# ---- Label Wrapping Helper ----

#' Internal helper
#' @keywords internal
#' @noRd
.wrap_labels <- function(labels, width = 35) {
  vapply(labels, function(x) {
    paste(strwrap(x, width = width), collapse = "\n")
  }, character(1), USE.NAMES = FALSE)
}

#' Build two-line "Attribute / level" labels: attribute on line 1, level on
#' line 2. Falls back to attribute alone when no level column is present.
#' Works with any conjoint dataset because it reads the `attribute` and
#' `level` columns populated by `.apply_labels()` / `attr_map`.
#'
#' @param wrap_width Optional character width for wrapping the level text.
#'   The attribute always stays on its own line.
#' @noRd
.make_level_label <- function(plot_data, wrap_width = NULL) {
  if (!"level" %in% names(plot_data)) {
    raw <- plot_data$attribute
    return(if (is.null(wrap_width)) raw else .wrap_labels(raw, wrap_width))
  }
  level_text <- if (is.null(wrap_width)) {
    plot_data$level
  } else {
    .wrap_labels(plot_data$level, width = wrap_width)
  }
  paste(plot_data$attribute, level_text, sep = "\n")
}

#' Render rotated x-axis tick labels with attribute in black and level in
#' darkgrey. Uses [ggtext::geom_richtext()] (geom layer, works under
#' ggplot2 4.0 + theme_minimal). Falls back to plain rotated `element_text`
#' if ggtext is unavailable.
#'
#' Returns a list of plot layers the caller adds with `+`. Caller must:
#'   - have `attribute`, `level`, `rank` columns in `plot_data`
#'   - keep `scale_x_continuous(breaks = plot_data$rank, ...)` so the ticks
#'     stay aligned (the labels are blanked when ggtext renders the rich
#'     text, kept as fallback otherwise)
#' @noRd
.add_xtick_labels <- function(plot_data) {
  if (!requireNamespace("ggtext", quietly = TRUE) ||
      !"level" %in% names(plot_data)) {
    return(list(ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 90, hjust = 1, vjust = 0.5
      )
    )))
  }

  rt <- paste0(
    "<span style='color:black'>", plot_data$attribute, "</span><br>",
    "<span style='color:#555555'>", plot_data$level, "</span>"
  )
  ld <- data.frame(rank = plot_data$rank, label_text = rt,
                   stringsAsFactors = FALSE)

  # Bottom margin scales with the longest label so the plot uses no more
  # whitespace than needed. The rotated label's vertical extent equals the
  # horizontal extent of its widest line; ~5.5pt per char is a reasonable
  # approximation for default fonts at base 11pt, plus a small buffer.
  longest <- max(
    nchar(plot_data$attribute, type = "width"),
    nchar(plot_data$level,     type = "width"),
    na.rm = TRUE
  )
  bottom_pt <- ceiling(longest * 5.5) + 15

  list(
    ggtext::geom_richtext(
      data = ld,
      mapping = ggplot2::aes(
        x = .data$rank, y = -Inf, label = .data$label_text
      ),
      angle = 90, hjust = 1, vjust = 0.5,
      fill = NA, label.color = NA, label.size = 0,
      inherit.aes = FALSE
    ),
    ggplot2::coord_cartesian(clip = "off"),
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(t = 5, r = 10, b = bottom_pt, l = 5)
    )
  )
}


# ---- Internal Plot Functions ----

#' Internal helper
#' @keywords internal
#' @noRd
.plot_importance <- function(results, top_n, metric = "mda", opts,
                             group_by_attribute = FALSE) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- utils::head(plot_data, top_n)
  plot_data$label <- .make_level_label(plot_data, wrap_width = opts$label_wrap)

  plot_data <- plot_data %>%
    dplyr::mutate(value = .data[[metric]]) %>%
    dplyr::arrange(value) %>%
    dplyr::mutate(label = factor(label, levels = label))

  metric_label <- switch(metric,
    "mda"        = "Mean Decrease in Accuracy (MDA)",
    "mdg"        = "Mean Decrease in Gini",
    "root_pct"   = "Root Node Appearance (%)",
    "importance" = "Variable Importance (rpart)",
    "mm"         = "Marginal Mean",
    metric
  )

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = label, y = value)) +
    ggplot2::geom_col(fill = opts$colors[["primary"]], width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = metric_label) +
    opts$theme +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.85)))

  if (group_by_attribute && "attribute" %in% names(plot_data)) {
    p <- p + ggplot2::facet_grid(
      attribute ~ ., scales = "free_y", space = "free_y"
    ) +
    ggplot2::theme(
      strip.text.y = ggplot2::element_text(angle = 0, hjust = 0, face = "bold")
    )
  }

  p
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_combined <- function(results, top_n, opts) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- utils::head(plot_data, top_n)
  plot_data$label <- .make_level_label(plot_data, wrap_width = opts$label_wrap)

  plot_data <- plot_data %>%
    dplyr::arrange(mda) %>%
    dplyr::mutate(label = factor(label, levels = rev(label)))

  max_mda <- max(plot_data$mda, na.rm = TRUE)
  max_root <- max(plot_data$root_pct, na.rm = TRUE)
  if (max_root == 0) max_root <- 1
  scale_factor <- max_mda / max_root

  plot_long <- plot_data %>%
    dplyr::mutate(root_scaled = root_pct * scale_factor) %>%
    dplyr::select(label, MDA = mda, `Root %` = root_scaled) %>%
    tidyr::pivot_longer(
      cols = c(MDA, `Root %`),
      names_to = "metric",
      values_to = "value"
    ) %>%
    dplyr::mutate(metric = factor(metric, levels = c("MDA", "Root %")))

  ggplot2::ggplot(plot_long,
                  ggplot2::aes(x = label, y = value, fill = metric)) +
    ggplot2::geom_col(
      position = ggplot2::position_dodge(width = 0.8), width = 0.7
    ) +
    ggplot2::scale_fill_manual(
      values = c("MDA" = opts$colors[["primary"]],
                 "Root %" = opts$colors[["secondary"]]),
      guide = "none"
    ) +
    ggplot2::scale_y_continuous(
      name = "Mean Decrease in Accuracy (MDA)",
      sec.axis = ggplot2::sec_axis(
        ~ . / scale_factor, name = "Root Node Appearance (%)"
      )
    ) +
    ggplot2::labs(x = NULL) +
    opts$theme +
    ggplot2::theme(
      panel.grid.major.x = ggplot2::element_blank(),
      axis.text.x        = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5),
      axis.title.y.left  = ggplot2::element_text(color = opts$colors[["primary"]]),
      axis.title.y.right = ggplot2::element_text(color = opts$colors[["secondary"]]),
      axis.text.y.right  = ggplot2::element_text(color = opts$colors[["secondary"]])
    )
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_rank <- function(results, top_n, opts) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- utils::head(plot_data, top_n)
  plot_data$label <- .make_level_label(plot_data)

  ggplot2::ggplot(plot_data, ggplot2::aes(x = rank, y = mda)) +
    ggplot2::geom_line(color = opts$colors[["primary"]], linewidth = 1) +
    ggplot2::geom_point(color = opts$colors[["primary"]], size = 3) +
    ggplot2::scale_x_continuous(
      breaks = plot_data$rank, labels = plot_data$label
    ) +
    ggplot2::labs(x = NULL, y = "Mean Decrease in Accuracy (MDA)") +
    opts$theme +
    .add_xtick_labels(plot_data)
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_cumulative <- function(results, top_n = NULL, opts) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- plot_data %>%
    dplyr::arrange(dplyr::desc(mda)) %>%
    dplyr::mutate(rank = dplyr::row_number())
  plot_data$label <- .make_level_label(plot_data)

  n_total <- nrow(plot_data)
  if (is.null(top_n)) top_n <- n_total
  top_n <- min(top_n, n_total)

  plot_data <- plot_data %>% dplyr::filter(rank <= top_n)

  ggplot2::ggplot(plot_data, ggplot2::aes(x = rank, y = mda)) +
    ggplot2::geom_line(color = opts$colors[["primary"]], linewidth = 1.2) +
    ggplot2::geom_point(color = opts$colors[["primary"]]) +
    ggplot2::scale_x_continuous(
      breaks = plot_data$rank, labels = plot_data$label
    ) +
    ggplot2::labs(x = NULL, y = "Mean Decrease in Accuracy (MDA)") +
    opts$theme +
    .add_xtick_labels(plot_data)
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_cumulative_pct <- function(results, top_n = NULL, opts) {

  plot_data <- .apply_labels(results, opts)
  # Clamp negative MDA to 0 (noise from RF can produce small negatives)
  mda_pos <- pmax(results$mda, 0)
  total_mda <- sum(mda_pos, na.rm = TRUE)
  if (total_mda == 0) total_mda <- 1  # avoid division by zero
  plot_data <- plot_data %>%
    dplyr::mutate(mda_clean = pmax(mda, 0)) %>%
    dplyr::arrange(dplyr::desc(mda_clean)) %>%
    dplyr::mutate(
      rank = dplyr::row_number(),
      cumulative_pct = pmin(100 * cumsum(mda_clean) / total_mda, 100)
    )

  n_total <- nrow(plot_data)
  if (is.null(top_n)) top_n <- n_total
  top_n <- min(top_n, n_total)

  plot_data <- plot_data %>% dplyr::filter(rank <= top_n)
  plot_data$label <- .make_level_label(plot_data)

  ggplot2::ggplot(plot_data, ggplot2::aes(x = rank, y = cumulative_pct)) +
    ggplot2::geom_area(fill = opts$colors[["primary"]], alpha = 0.3) +
    ggplot2::geom_line(linewidth = 1.2, color = opts$colors[["primary"]]) +
    ggplot2::geom_point(color = opts$colors[["primary"]]) +
    ggplot2::scale_x_continuous(
      breaks = plot_data$rank, labels = plot_data$label
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, 20)) +
    ggplot2::labs(x = NULL, y = "Cumulative % of Total MDA") +
    opts$theme +
    .add_xtick_labels(plot_data)
}


# ---- NMM-specific Plot Functions ----



#' Internal helper
#' @keywords internal
#' @noRd
.plot_nmm_cumulative <- function(results, top_n = NULL, opts) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- plot_data %>%
    dplyr::filter(!is.na(pct_of_total))

  if (!is.null(top_n)) plot_data <- utils::head(plot_data, top_n)

  if (!"cumulative_pct" %in% names(plot_data) || all(is.na(plot_data$cumulative_pct))) {
    plot_data <- plot_data %>%
      dplyr::mutate(cumulative_pct = cumsum(pct_of_total))
  }

  plot_data$label <- .make_level_label(plot_data)

  ggplot2::ggplot(plot_data, ggplot2::aes(x = rank, y = cumulative_pct)) +
    ggplot2::geom_area(fill = opts$colors[["primary"]], alpha = 0.3) +
    ggplot2::geom_line(linewidth = 1.2, color = opts$colors[["primary"]]) +
    ggplot2::geom_point(color = opts$colors[["primary"]]) +
    ggplot2::scale_x_continuous(
      breaks = plot_data$rank, labels = plot_data$label
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, 20)) +
    ggplot2::labs(x = NULL, y = "Cumulative % of Choices Explained") +
    opts$theme +
    .add_xtick_labels(plot_data)
}



# ---- CRT-specific Plot Functions ----

#' Internal helper
#' @keywords internal
#' @noRd
.plot_crt_robustness <- function(results, top_n, opts) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- plot_data %>%
    dplyr::filter(max_lambda > 0) %>%
    dplyr::arrange(dplyr::desc(max_lambda))
  if (!is.null(top_n)) plot_data <- utils::head(plot_data, top_n)

  if (nrow(plot_data) == 0) {
    plot_data <- .apply_labels(results, opts)
    if (!is.null(top_n)) plot_data <- utils::head(plot_data, top_n)
  }

  plot_data$label <- .make_level_label(plot_data, wrap_width = opts$label_wrap)

  plot_data <- plot_data %>%
    dplyr::arrange(max_lambda) %>%
    dplyr::mutate(label = factor(label, levels = label))

  ggplot2::ggplot(plot_data,
                  ggplot2::aes(x = label, y = max_lambda)) +
    ggplot2::geom_col(fill = opts$colors[["primary"]], width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = "Max Lambda Survived") +
    opts$theme +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.85)))
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_crt_rank <- function(results, top_n, opts) {

  plot_data <- .apply_labels(results, opts)
  plot_data <- plot_data %>%
    dplyr::arrange(dplyr::desc(max_lambda)) %>%
    dplyr::mutate(rank = dplyr::row_number())
  if (!is.null(top_n)) plot_data <- utils::head(plot_data, top_n)
  plot_data$label <- .make_level_label(plot_data, wrap_width = opts$label_wrap)

  ggplot2::ggplot(plot_data, ggplot2::aes(x = rank, y = max_lambda)) +
    ggplot2::geom_line(color = opts$colors[["primary"]], linewidth = 0.7) +
    ggplot2::geom_point(color = opts$colors[["primary"]], size = 2.3) +
    ggplot2::scale_x_continuous(breaks = plot_data$rank,
                                labels = plot_data$label) +
    ggplot2::labs(x = NULL,
                  y = expression("Survival statistic: max " * lambda)) +
    opts$theme +
    .add_xtick_labels(plot_data)
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_crt_survival <- function(results, path_coefs, lambda_grid, top_n, opts) {

  attended_mat <- abs(path_coefs) > 1e-6

  # Order levels by survival (max lambda where the coefficient stayed nonzero),
  # not by permutation MDA. Permutation MDA at the optimal lambda systematically
  # under-prioritises gatekeeper levels whose coefficients are far past the
  # decision boundary -- permuting them rarely flips a predicted class, so MDA
  # looks small even though they survive the heaviest penalisation. A survival
  # plot should rank by survival.
  surv_order <- results %>%
    dplyr::arrange(dplyr::desc(max_lambda), dplyr::desc(mda)) %>%
    dplyr::pull(var_name)
  surv_order <- surv_order[surv_order %in% rownames(attended_mat)]

  top_levels <- if (is.null(top_n)) surv_order else utils::head(surv_order, top_n)

  if (length(top_levels) == 0) {
    stop("No matching levels found for survival plot", call. = FALSE)
  }

  attended_sub <- attended_mat[top_levels, , drop = FALSE]

  heat_data <- expand.grid(
    var_name = top_levels,
    lambda = lambda_grid,
    stringsAsFactors = FALSE
  )
  heat_data$status <- vapply(seq_len(nrow(heat_data)), function(i) {
    ifelse(attended_sub[heat_data$var_name[i],
                        as.character(heat_data$lambda[i])],
           "Attended", "Ignored")
  }, character(1))

  label_map <- .apply_labels(results, opts) %>%
    dplyr::select(var_name, attribute, level) %>%
    dplyr::mutate(label = paste0(attribute, ": ", level))

  heat_data <- dplyr::left_join(heat_data, label_map, by = "var_name")

  # y-axis: longest-surviving level at the top (reverse so factor's first level
  # plots at the bottom of the panel).
  level_order <- rev(top_levels)
  label_order <- label_map$label[match(level_order, label_map$var_name)]
  heat_data$label <- factor(heat_data$label, levels = label_order)

  ggplot2::ggplot(heat_data,
                  ggplot2::aes(x = factor(lambda), y = label, fill = status)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.5) +
    ggplot2::scale_fill_manual(
      values = c("Attended" = opts$colors[["primary"]],
                 "Ignored" = opts$colors[["tertiary"]]),
      name = "Status"
    ) +
    ggplot2::labs(x = "Lambda", y = NULL) +
    opts$theme +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = ggplot2::rel(0.75))
    )
}


#' Internal helper
#' @keywords internal
#' @noRd
.plot_crt_cv <- function(cv_results, optimal_lambda, lambda_1se, opts) {

  plot_data <- cv_results %>%
    dplyr::mutate(
      lower = mean_deviance - sd_deviance,
      upper = mean_deviance + sd_deviance
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = lambda, y = mean_deviance)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = lower, ymax = upper),
      alpha = 0.2, fill = opts$colors[["primary"]]
    ) +
    ggplot2::geom_line(linewidth = 1, color = opts$colors[["primary"]]) +
    ggplot2::geom_point(size = 3, color = opts$colors[["primary"]]) +
    ggplot2::geom_vline(xintercept = optimal_lambda, linetype = "dashed",
                        color = opts$colors[["secondary"]], linewidth = 0.8) +
    ggplot2::geom_vline(xintercept = lambda_1se, linetype = "dotted",
                        color = "grey50", linewidth = 0.8) +
    ggplot2::labs(
      x = "Lambda (regularization strength)",
      y = "Mean CV Deviance"
    ) +
    opts$theme
}
