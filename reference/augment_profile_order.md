# Augment Data with Swapped Profile Order

Doubles the dataset by swapping left/right profiles and inverting the
outcome. This satisfies the profile order constraint required for valid
CRT hypothesis testing with HierNet. Apply this BEFORE calling
[`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md) with
`method = "crt"`.

## Usage

``` r
augment_profile_order(data, outcome, left, right)
```

## Arguments

- data:

  A data frame containing conjoint data.

- outcome:

  Character name of the binary outcome column (0/1).

- left:

  Character vector of column names for the left profile attributes.

- right:

  Character vector of column names for the right profile attributes.
  Must be the same length as `left`.

## Value

A data frame with `2 * nrow(data)` rows: the original data followed by
the swapped copy (left/right exchanged, outcome inverted).

## Examples

``` r
# \donttest{
if (requireNamespace("CRTConjoint", quietly = TRUE)) {
  data("immigrationdata", package = "CRTConjoint")
  left <- colnames(immigrationdata)[1:9]
  right <- colnames(immigrationdata)[10:18]
  augmented <- augment_profile_order(immigrationdata, "Y", left, right)
  nrow(augmented)  # doubled
}
# }
```
