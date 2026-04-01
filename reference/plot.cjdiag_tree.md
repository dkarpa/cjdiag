# Plot Decision Tree

Renders the decision tree using
[`rpart.plot::rpart.plot()`](https://rdrr.io/pkg/rpart.plot/man/rpart.plot.html)
(default) or plots variable importance as a bar chart
(`type = "importance"`).

## Usage

``` r
# S3 method for class 'cjdiag_tree'
plot(
  x,
  type = "tree",
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

  A `cjdiag_tree` object from
  [`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md)

- type:

  `"tree"` (default, renders via rpart.plot) or `"importance"` (ggplot
  bar chart)

- top_n:

  Number of levels to display for importance plot (default 25)

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

  Additional arguments passed to
  [`rpart.plot::rpart.plot()`](https://rdrr.io/pkg/rpart.plot/man/rpart.plot.html)
  (for `type = "tree"`) or to the primary ggplot2 geom (for
  `type = "importance"`)

## Value

A ggplot object (for `type = "importance"`) or invisible NULL (for
`type = "tree"`)

## Examples

``` r
# \donttest{
df <- data.frame(
  y = sample(0:1, 200, TRUE),
  a = factor(sample(c("x","y"), 200, TRUE)),
  b = factor(sample(c("p","q","r"), 200, TRUE))
)
tr <- cj_fit(y ~ a + b, data = df, method = "tree")
plot(tr, type = "importance")

# }
```
