# Plot Importance Results

Plot Importance Results

## Usage

``` r
# S3 method for class 'cjdiag_importance'
plot(
  x,
  type = "mda",
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

  A `cjdiag_importance` object from
  [`importance()`](https://dkarpa.github.io/cjdiag/reference/importance.md)

- type:

  Plot type: `"mda"` (default), `"root"`, `"combined"`, or
  `"cumulative"`

- top_n:

  Number of items to display (default 25; NULL = all levels).

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

## Examples

``` r
# \donttest{
df <- data.frame(
  y = sample(0:1, 200, TRUE),
  a = factor(sample(c("x","y"), 200, TRUE)),
  b = factor(sample(c("p","q","r"), 200, TRUE))
)
rf <- cj_fit(y ~ a + b, data = df, method = "forest")
imp <- importance(rf)
plot(imp)

# }
```
