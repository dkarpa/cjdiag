# Getting Started with cjdiag

## What cjdiag does

Standard conjoint analysis tools estimate Average Marginal Component
Effects (AMCEs) — the causal effect of changing a single attribute
level. AMCEs tell you *what* respondents prefer, but not *how* they
decide: which attribute levels they actually attend to, which ones they
ignore, and in what order they process information.

**cjdiag** fills this gap. It works at the level of individual
**attribute levels** — not aggregated attributes — because the specific
level (e.g., “no plans to look for work”, not just “Job Plans” as a
whole) is what triggers respondent decisions.

## Choosing a method

| Estimand | `method =` | Question | Output | Behavioural assumption | When to use |
|----|----|----|----|----|----|
| **Level importance** | `"forest"` | Which attribute levels matter most? | MDA, root-split rate per level | None — non-parametric | Default. Always fit this first. |
| **Decision structure** | `"tree"` | How do respondents structure their decisions? | Hierarchical CART splits | Lexicographic / sequential | When you suspect a gatekeeper. |
| **Level attendance** | `"crt"` | Which levels survive a strict signal-vs-noise test? | Lambda-survival, attended/ignored | Sparsity (most levels are noise) | When you want a hard attendance test. |
| **Decision order** | `"nmm"` | In what order do levels settle choices? | Decisiveness ranking, cumulative % | Sequential elimination (EBA) | When you care about the decision *order*. |
| **Individual attendance** | `"marginal_r2"` | Which attributes did each respondent actually use? | Per-respondent R² matrix | Per-respondent simple-regression fit | When you want individual-level heterogeneity. |

Each method has its own task-oriented vignette:

- [Random Forest](https://dkarpa.github.io/cjdiag/articles/forest.md):
  default level-importance.
- [Decision Tree](https://dkarpa.github.io/cjdiag/articles/tree.md):
  hierarchical decision structure.
- [Nested Marginal
  Means](https://dkarpa.github.io/cjdiag/articles/nmm.md): decision
  *order*.
- [Marginal
  R-squared](https://dkarpa.github.io/cjdiag/articles/marginal_r2.md):
  individual-level attendance.
- [CRT / HierNet](https://dkarpa.github.io/cjdiag/articles/crt.md):
  regularization-robust level selection.

## Quick start

``` r

library(cjdiag)
data(immig)

f <- Chosen_Immigrant ~ Gender + Education + LanguageSkills +
  CountryofOrigin + Job + JobExperience + JobPlans +
  ReasonforApplication + PriorEntry

rf <- cj_fit(f, data = immig, method = "forest")
rf
#> Conjoint Random Forest 
#> ====================== 
#> 
#> Resolution: levels
#> Trees: 500
#> OOB Error: 40.3%
#> Observations: 2,000
#> Attributes: 9
#> Levels: 50
#> 
#> Top 10 levels by MDA:
#> 
#> # A tibble: 10 × 7
#>     rank attribute       level                      mda root_pct class_0 class_1
#>    <int> <chr>           <chr>                    <dbl>    <dbl>   <dbl>   <dbl>
#>  1     1 JobPlans        no plans to look for wo… 13.5      15.4  12.3      7.25
#>  2     2 JobPlans        contract with employer    8.18     11.2   3.70     6.98
#>  3     3 Education       no formal                 7.87      7.4   8.04     2.38
#>  4     4 PriorEntry      once w/o authorization    7.42     10.4   6.87     3.66
#>  5     5 LanguageSkills  fluent English            6.16      8.2   2.71     6.00
#>  6     6 PriorEntry      once as tourist           4.83      2.4   1.61     5.25
#>  7     7 Education       college degree            4.75      6.4   0.153    6.16
#>  8     8 LanguageSkills  used interpreter          4.66      5.6   4.91     1.37
#>  9     9 CountryofOrigin Iraq                      4.15      4.6   3.53     2.15
#> 10    10 Job             janitor                   3.87      3     2.09     3.36
```

``` r

plot(rf, type = "rank", top_n = 20)
```

![](cjdiag_files/figure-html/quick-plot-1.png)

## Plot customization

All plot methods return ggplot2 objects and accept customization:

``` r

plot(rf,
     palette = "colorblind",
     attribute.names = c(LanguageSkills = "English Proficiency",
                         JobPlans = "Plans for Employment"),
     top_n = 20)
```

![](cjdiag_files/figure-html/custom-plot-1.png)

Three palettes: `"default"`, `"colorblind"` (Okabe-Ito), `"grey"`.

Set global defaults with
[`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md)
and
[`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md)
so all plots use the same settings without repeating arguments.
