# Color Palettes for cjdiag Plots

Returns a named character vector of colors for use in cjdiag plots.

## Usage

``` r
cjdiag_palette(palette = "default", n = 3)
```

## Arguments

- palette:

  Palette name: `"default"`, `"colorblind"` (Okabe-Ito), or `"grey"`

- n:

  Number of colors (currently ignored; always returns 3)

## Value

Named character vector with elements `primary`, `secondary`, `tertiary`

## See also

Other customization:
[`get_cjdiag_options()`](https://dkarpa.github.io/cjdiag/reference/get_cjdiag_options.md),
[`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md),
[`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md),
[`theme_cjdiag()`](https://dkarpa.github.io/cjdiag/reference/theme_cjdiag.md)

## Examples

``` r
cjdiag_palette("default")
#>   primary secondary  tertiary 
#> "#2171b5" "#d62728" "#d3d3d3" 
cjdiag_palette("colorblind")
#>   primary secondary  tertiary 
#> "#0072B2" "#D55E00" "#999999" 
```
