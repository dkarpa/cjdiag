# Apply Label Remapping to Plot Data (internal)

Renames attribute and level values in a data frame using the label
dictionaries from explicit arguments or global options.

## Usage

``` r
.apply_labels(data, opts)
```

## Arguments

- data:

  Data frame with `attribute` and optionally `level` columns

- opts:

  Options list from
  [`.resolve_plot_options()`](https://dkarpa.github.io/cjdiag/reference/dot-resolve_plot_options.md)

## Value

Modified data frame with relabeled values
