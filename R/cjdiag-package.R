#' cjdiag: Diagnostic Tools for Conjoint Survey Experiments
#'
#' Tools for attribute-level importance and attendance in conjoint survey
#' experiments — which attribute levels drive choices, how they rank, and
#' which ones respondents ignore.
#'
#' @section Entry Points:
#' \itemize{
#'   \item [cj_fit()] — Fits one of 5 methods: `"forest"`, `"tree"`, `"crt"`,
#'     `"nmm"`, `"marginal_r2"`
#' }
#'
#' @section Common Workflow:
#' \preformatted{
#' # 1. Fit a model
#' rf <- cj_fit(outcome ~ attr1 + attr2, data = df, method = "forest")
#'
#' # 2. View results
#' print(rf)
#' importance(rf)
#'
#' # 3. Visualize
#' plot(rf)
#' plot(rf, palette = "colorblind", group_by_attribute = TRUE)
#' }
#'
#' @section Customization:
#' All plot methods support `base_size`, `colors`, `palette`, `theme`,
#' `label_wrap`, `attribute.names`, and `level.names` parameters.
#' Use [set_cjdiag_theme()] and [set_cjdiag_labels()] to set global defaults.
#'
"_PACKAGE"

## usethis namespace: start
#' @importFrom stats as.formula lm median sd model.matrix predict setNames
#' @importFrom utils head
#' @importFrom dplyr %>% mutate filter select arrange group_by summarize
#'   left_join row_number desc n pull
#' @importFrom tidyr pivot_longer
#' @importFrom tibble tibble as_tibble
#' @importFrom rlang .data %||%
#' @importFrom cli cli_abort
#' @importFrom ggplot2 ggplot aes geom_col geom_point geom_line geom_text
#'   coord_flip coord_cartesian scale_fill_manual scale_y_continuous
#'   scale_x_continuous sec_axis labs theme_minimal theme element_blank
#'   element_text element_line margin position_dodge rel facet_grid
## usethis namespace: end
NULL

#' @importFrom dplyr %>%
#' @export
dplyr::`%>%`
