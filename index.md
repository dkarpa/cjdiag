# cjdiag

Tools for attribute-level importance and attendance in conjoint survey
experiments — which attribute levels drive choices, how they rank, and
which ones respondents ignore.

## Installation

``` r
# From CRAN
install.packages("cjdiag")

# Development version from GitHub
# install.packages("pak")
pak::pak("dkarpa/cjdiag")
```

## Quick Start

``` r
library(cjdiag)
data(immig)

# Fit a random forest
rf <- cj_fit(Chosen_Immigrant ~ Gender + Education + LanguageSkills +
             CountryofOrigin + Job + JobExperience + JobPlans +
             ReasonforApplication + PriorEntry,
             data = immig, method = "forest")

# View results
print(rf)
plot(rf)
importance(rf)
```

## Methods

| Method        | `method =`      | Question                                           |
|---------------|-----------------|----------------------------------------------------|
| Random Forest | `"forest"`      | Which attributes matter most for choices?          |
| Decision Tree | `"tree"`        | How do respondents structure their decisions?      |
| CRT/HierNet   | `"crt"`         | Which attribute levels genuinely drive choices?    |
| Nested MM     | `"nmm"`         | In what order do attributes settle choices?        |
| Marginal R-sq | `"marginal_r2"` | Which attributes did each respondent actually use? |

## Plot Customization

All plot methods accept customization parameters:

``` r
# Custom palette
plot(rf, palette = "colorblind")

# Custom base size and label wrapping
plot(rf, base_size = 14, label_wrap = 25)

# Rename attributes in display
plot(rf, attribute.names = c(LanguageSkills = "English Proficiency"))

# Group by attribute (cregg-style feature headers)
plot(rf, group_by_attribute = TRUE)

# Full ggplot2 theme override
plot(rf, theme = ggplot2::theme_classic(base_size = 14))
```

Available palettes: `"default"`, `"colorblind"` (Okabe-Ito), `"grey"`.

## Global Options

Set defaults once, apply everywhere:

``` r
# Set global theme
set_cjdiag_theme(palette = "colorblind", base_size = 14, print_n = 15)

# Set label dictionary
set_cjdiag_labels(
  attribute.names = c(JobPlans = "Plans for Employment",
                      LanguageSkills = "English Proficiency")
)

# All subsequent plots use these defaults
plot(rf)

# Explicit arguments always override globals
plot(rf, palette = "grey")

# Check current options
get_cjdiag_options()

# Reset
set_cjdiag_theme()
set_cjdiag_labels(reset = TRUE)
```

## Tidy Output

If `broom` is installed, `tidy()` and `glance()` work on all model
objects:

``` r
tidy(rf)    # results tibble
glance(rf)  # single-row model summary
```

## Citation

``` r
citation("cjdiag")
```
