# Set Global Plot Theme Options

Configure default plotting options for all cjdiag plots. These serve as
the middle-priority layer: explicit function arguments override these,
and these override the hardcoded package defaults.

## Usage

``` r
set_cjdiag_theme(
  base_size = 12,
  palette = "default",
  font_family = "",
  label_wrap = 35L,
  theme = NULL,
  print_n = 10L
)
```

## Arguments

- base_size:

  Default font size for plots (default 12)

- palette:

  Default color palette: `"default"`, `"colorblind"`, or `"grey"`
  (default `"default"`)

- font_family:

  Default font family (default `""`)

- label_wrap:

  Default character width for label wrapping (default 35)

- theme:

  A complete
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  object to use as default (default `NULL`, uses
  [`theme_cjdiag()`](https://dkarpa.github.io/cjdiag/reference/theme_cjdiag.md))

- print_n:

  Default number of rows shown by
  [`print()`](https://rdrr.io/r/base/print.html) methods (default 10)

## Value

Invisibly returns the previous options (for save/restore pattern)

## Details

Calling with no arguments resets all options to defaults.

## See also

Other customization:
[`cjdiag_palette()`](https://dkarpa.github.io/cjdiag/reference/cjdiag_palette.md),
[`get_cjdiag_options()`](https://dkarpa.github.io/cjdiag/reference/get_cjdiag_options.md),
[`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md),
[`theme_cjdiag()`](https://dkarpa.github.io/cjdiag/reference/theme_cjdiag.md)

## Examples

``` r
# Set colorblind-friendly defaults
old <- set_cjdiag_theme(palette = "colorblind", base_size = 14)

# Reset to defaults
set_cjdiag_theme()

# Restore previous options
if (FALSE) { # \dontrun{
do.call(set_cjdiag_theme, old)
} # }
```
