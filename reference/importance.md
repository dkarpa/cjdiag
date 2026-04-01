# Extract Importance Metrics from Fitted Model

Extracts importance metrics from a fitted conjoint diagnostic model.
Returns the results at whatever resolution the model was fitted at:
level-specific (if `resolution = "levels"`) or attribute-level (if
`resolution = "attributes"`).

## Usage

``` r
importance(x, ...)
```

## Arguments

- x:

  A fitted model object from
  [`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md)

- ...:

  Additional arguments (unused)

## Value

A `cjdiag_importance` object (a list) containing:

- results:

  Tibble with importance metrics at the fitted resolution

- method:

  Character: `"forest"` or `"tree"`

- resolution:

  Character: `"levels"` or `"attributes"`

## Examples

``` r
# \donttest{
df <- data.frame(
  y = sample(0:1, 200, TRUE),
  a = factor(sample(c("x","y"), 200, TRUE)),
  b = factor(sample(c("p","q","r"), 200, TRUE))
)
rf <- cj_fit(y ~ a + b, data = df, method = "forest")
imp <- importance(rf)
print(imp)
#> Conjoint Importance Metrics 
#> =========================== 
#> 
#> Resolution: levels
#> Method: Random Forest (500 trees)
#> OOB Error: 56.5%
#> 
#> Level Importance (top 5 ):
#> 
#> # A tibble: 5 × 9
#>    rank attribute level   mda   mdg root_pct class_0 class_1 var_name
#>   <int> <chr>     <chr> <dbl> <dbl>    <dbl>   <dbl>   <dbl> <chr>   
#> 1     1 b         q     10.7  2.05      38.8  5.03     8.87  bq      
#> 2     2 b         r      3.14 1.14      23.4  5.35    -2.10  br      
#> 3     3 a         y      1.37 0.876     15   -0.0745   2.05  ay      
#> 4     4 a         x     -1.03 1.03      11.4 -1.53    -0.178 ax      
#> 5     5 b         p     -2.90 0.740     11.4 -0.398   -2.80  bp      
as.data.frame(imp)
#>   rank attribute level       mda       mdg root_pct     class_0   class_1
#> 1    1         b     q 10.698377 2.0492472     38.8  5.02811272  8.865870
#> 2    2         b     r  3.137717 1.1412145     23.4  5.34772910 -2.101405
#> 3    3         a     y  1.366344 0.8759098     15.0 -0.07452591  2.053108
#> 4    4         a     x -1.032809 1.0286025     11.4 -1.52541963 -0.177525
#> 5    5         b     p -2.902232 0.7395296     11.4 -0.39782900 -2.803436
#>   var_name
#> 1       bq
#> 2       br
#> 3       ay
#> 4       ax
#> 5       bp
# }
```
