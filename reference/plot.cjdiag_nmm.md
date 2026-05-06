# Plot Nested Marginal Means Results

Plots the cumulative percentage of choices explained by the top
attribute levels in order of decisiveness.

## Usage

``` r
# S3 method for class 'cjdiag_nmm'
plot(
  x,
  top_n = NULL,
  base_size = NULL,
  colors = NULL,
  palette = NULL,
  theme = NULL,
  label_wrap = NULL,
  attribute.names = NULL,
  level.names = NULL,
  ...
)
```

## Arguments

- x:

  A `cjdiag_nmm` object from
  [`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md)

- top_n:

  Number of levels to display (default 25; NULL = all).

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

- ...:

  Additional arguments passed to primary ggplot2 geom

## Value

A ggplot object

## See also

Other plotting:
[`plot.cjdiag_crt()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_crt.md),
[`plot.cjdiag_forest()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_forest.md),
[`plot.cjdiag_importance()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_importance.md),
[`plot.cjdiag_tree()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_tree.md)

## Examples

``` r
# \donttest{
df <- data.frame(
  y = sample(0:1, 200, TRUE),
  a = factor(sample(c("x","y"), 200, TRUE)),
  b = factor(sample(c("p","q","r"), 200, TRUE)),
  id = rep(1:100, each = 2)
)
nmm <- cj_fit(y ~ a + b, data = df, method = "nmm", resp_id = "id", n_boot = 0)
plot(nmm)

# }
```
