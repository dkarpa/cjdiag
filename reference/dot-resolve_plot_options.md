# Resolve Plot Options (internal)

Three-tier priority: explicit arg \> global options \> hardcoded
default.

## Usage

``` r
.resolve_plot_options(
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

- base_size:

  Numeric or NULL

- colors:

  Named character vector or NULL

- palette:

  Palette name or NULL

- theme:

  ggplot2 theme object or NULL

- label_wrap:

  Integer label wrap width or NULL

- attribute.names:

  Named character vector for relabeling attributes

- level.names:

  Named list for relabeling levels

- ...:

  Extra arguments (currently unused, reserved for future extensions)

## Value

List with: base_size, colors, theme, label_wrap, attribute.names,
level.names
