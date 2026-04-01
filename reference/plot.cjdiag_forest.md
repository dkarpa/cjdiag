# Plot Random Forest Results

Plot Random Forest Results

## Usage

``` r
# S3 method for class 'cjdiag_forest'
plot(
  x,
  type = "importance",
  top_n = NULL,
  base_size = NULL,
  colors = NULL,
  palette = NULL,
  theme = NULL,
  label_wrap = NULL,
  attribute.names = NULL,
  level.names = NULL,
  group_by_attribute = FALSE,
  ...
)
```

## Arguments

- x:

  A `cjdiag_forest` object from
  [`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md)

- type:

  Plot type: `"importance"` (default), `"combined"`, `"rank"`,
  `"cumulative"` (MDA rank-decay with labels), or `"cumulative_pct"`
  (cumulative % of total MDA, area chart like NMM cumulative)

- top_n:

  Number of levels to display (default 25; NULL = all levels). For
  `"cumulative"`, defaults to all levels if not specified.

- base_size:

  Font size (default from global options or 12)

- colors:

  Named character vector overriding specific palette colors

- palette:

  Palette name: `"default"`, `"colorblind"`, or `"grey"`

- theme:

  A complete
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  object (overrides all theme defaults)

- label_wrap:

  Character width for label wrapping (default 35)

- attribute.names:

  Named character vector renaming attributes in display

- level.names:

  Named list for renaming levels

- group_by_attribute:

  Group levels by attribute with visual separators (default `FALSE`)

- ...:

  Additional arguments passed to primary ggplot2 geom

## Value

A ggplot object

## Examples

``` r
# \donttest{
df <- data.frame(
  y = sample(0:1, 200, TRUE),
  a = factor(sample(c("x","y"), 200, TRUE)),
  b = factor(sample(c("p","q","r"), 200, TRUE))
)
rf <- cj_fit(y ~ a + b, data = df, method = "forest")
plot(rf)

plot(rf, palette = "colorblind", base_size = 14)

plot(rf, type = "combined")

plot(rf, group_by_attribute = TRUE)

# }
```
