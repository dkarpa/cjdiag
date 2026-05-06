# Marginal R-squared: Which attributes did each respondent actually use?

## When to use

Use `method = "marginal_r2"` (Jenke, Bansak, Hainmueller and Hangartner
2021) when you care about *individual-level* heterogeneity in attribute
attendance — which respondents used which attributes. The other methods
aggregate across respondents; this one does not.

For each respondent, the method regresses their choices on each
attribute *alone* and reports the R². A respondent with R² near zero for
an attribute likely ignored it entirely.

``` r

library(cjdiag)
data(immig)

f <- Chosen_Immigrant ~ Gender + Education + LanguageSkills +
  CountryofOrigin + Job + JobExperience + JobPlans +
  ReasonforApplication + PriorEntry
```

## Fit

``` r

mr2 <- cj_fit(f, data = immig, method = "marginal_r2", resp_id = "CaseID")
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
#> Warning in summary.lm(fit): essentially perfect fit: summary may be unreliable
mr2
#> Conjoint Marginal R-squared Importance (Jenke et al. 2021) 
#> ========================================================== 
#> 
#> Resolution: levels
#> Respondents: 200
#> Observations: 2,000
#> Attributes: 9 (50 levels)
#> 
#> Top 10 levels by mean absolute coefficient:
#> 
#> # A tibble: 10 × 7
#>     rank attribute       level      mean_coef mean_abs_coef sd_coef attr_mean_r2
#>    <int> <chr>           <chr>          <dbl>         <dbl>   <dbl>        <dbl>
#>  1     1 Job             research …   0.161           0.637   0.743        0.194
#>  2     2 Job             construct…   0.0384          0.603   0.699        0.194
#>  3     3 CountryofOrigin France       0.0519          0.574   0.703        0.193
#>  4     4 CountryofOrigin India        0.00745         0.567   0.689        0.193
#>  5     5 Job             teacher      0.116           0.553   0.653        0.194
#>  6     6 CountryofOrigin Poland       0.00940         0.547   0.673        0.193
#>  7     7 Job             janitor     -0.123           0.547   0.650        0.194
#>  8     8 Job             doctor       0.126           0.540   0.670        0.194
#>  9     9 CountryofOrigin Somalia      0.0603          0.538   0.667        0.193
#> 10    10 CountryofOrigin Germany      0.0108          0.537   0.665        0.193
```

The print output gives the mean / median R² per attribute and the share
of respondents with R² = 0 (the per-attribute non-attendance rate).

## Per-respondent matrix

The full per-respondent × per-attribute R² matrix is on the fit object:

``` r

str(mr2$individual_r2)
#>  NULL
```

You can summarise this however you like — e.g. count the number of
attributes each respondent used (R² above some threshold) to study
heterogeneity in attendance breadth.

## Related

- [CRT / HierNet](https://dkarpa.github.io/cjdiag/articles/crt.md) for
  an aggregate, regularization-based attendance test.
- [Random Forest](https://dkarpa.github.io/cjdiag/articles/forest.md)
  for population-level importance.
