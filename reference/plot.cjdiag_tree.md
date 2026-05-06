# Plot Decision Tree

Renders the decision tree using
[`rpart.plot::rpart.plot()`](https://rdrr.io/pkg/rpart.plot/man/rpart.plot.html).

## Usage

``` r
# S3 method for class 'cjdiag_tree'
plot(x, ...)
```

## Arguments

- x:

  A `cjdiag_tree` object from
  [`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md)

- ...:

  Additional arguments passed to
  [`rpart.plot::rpart.plot()`](https://rdrr.io/pkg/rpart.plot/man/rpart.plot.html)

## Value

Invisible NULL (called for side effect of plotting)

## See also

Other plotting:
[`plot.cjdiag_crt()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_crt.md),
[`plot.cjdiag_forest()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_forest.md),
[`plot.cjdiag_importance()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_importance.md),
[`plot.cjdiag_nmm()`](https://dkarpa.github.io/cjdiag/reference/plot.cjdiag_nmm.md)

## Examples

``` r
# \donttest{
df <- data.frame(
  y = sample(0:1, 200, TRUE),
  a = factor(sample(c("x","y"), 200, TRUE)),
  b = factor(sample(c("p","q","r"), 200, TRUE))
)
tr <- cj_fit(y ~ a + b, data = df, method = "tree")
plot(tr)

# }
```
