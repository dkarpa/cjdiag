# Get Global cjdiag Options

Get Global cjdiag Options

## Usage

``` r
get_cjdiag_options(what = NULL)
```

## Arguments

- what:

  Optional: name of a specific option to retrieve (e.g., `"base_size"`,
  `"palette"`, `"labels"`). If `NULL`, returns all options.

## Value

The requested option value, or a list of all options

## See also

Other customization:
[`cjdiag_palette()`](https://dkarpa.github.io/cjdiag/reference/cjdiag_palette.md),
[`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md),
[`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md),
[`theme_cjdiag()`](https://dkarpa.github.io/cjdiag/reference/theme_cjdiag.md)

## Examples

``` r
get_cjdiag_options()
#> $base_size
#> [1] 12
#> 
#> $palette
#> [1] "default"
#> 
#> $font_family
#> [1] ""
#> 
#> $label_wrap
#> [1] 35
#> 
#> $theme
#> NULL
#> 
#> $print_n
#> [1] 10
#> 
#> $labels
#> $labels$attribute.names
#> NULL
#> 
#> $labels$level.names
#> NULL
#> 
#> 
get_cjdiag_options("palette")
#> [1] "default"
```
