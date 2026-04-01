# Custom ggplot2 Theme for cjdiag

A publication-ready theme based on
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
with consistent defaults used across all cjdiag plots. Removes minor
gridlines, controls major gridlines, and positions the legend at top.

## Usage

``` r
theme_cjdiag(base_size = 12, base_family = "", grid_y = FALSE, grid_x = TRUE)
```

## Arguments

- base_size:

  Base font size (default 12)

- base_family:

  Base font family (default `""`)

- grid_y:

  Show horizontal gridlines (default `FALSE`)

- grid_x:

  Show vertical gridlines (default `TRUE`)

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object

## See also

Other customization:
[`cjdiag_palette()`](https://dkarpa.github.io/cjdiag/reference/cjdiag_palette.md),
[`get_cjdiag_options()`](https://dkarpa.github.io/cjdiag/reference/get_cjdiag_options.md),
[`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md),
[`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md)

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_cjdiag()
```
