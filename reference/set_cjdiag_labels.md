# Set Global Label Dictionary

Configure a label dictionary for renaming attributes and levels in all
cjdiag plot and print output. Inspired by `fixest::setFixest_dict()`.

## Usage

``` r
set_cjdiag_labels(attribute.names = NULL, level.names = NULL, reset = FALSE)
```

## Arguments

- attribute.names:

  Named character vector mapping original attribute names to display
  names, e.g., `c(LanguageSkills = "English Proficiency")`

- level.names:

  Named list of named character vectors for level renaming, e.g.,
  `list(Gender = c(female = "Female", male = "Male"))`

- reset:

  If `TRUE`, clears the label dictionary (default `FALSE`)

## Value

Invisibly returns the previous labels

## See also

Other customization:
[`cjdiag_palette()`](https://dkarpa.github.io/cjdiag/reference/cjdiag_palette.md),
[`get_cjdiag_options()`](https://dkarpa.github.io/cjdiag/reference/get_cjdiag_options.md),
[`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md),
[`theme_cjdiag()`](https://dkarpa.github.io/cjdiag/reference/theme_cjdiag.md)

## Examples

``` r
set_cjdiag_labels(
  attribute.names = c(LanguageSkills = "English Proficiency",
                      JobPlans = "Plans for Employment")
)

# Reset
set_cjdiag_labels(reset = TRUE)
```
