# Changelog

## cjdiag 0.2.0

Initial CRAN release.

### Methods

- **Random forest** (`method = "forest"`): attribute importance via Mean
  Decrease in Accuracy, Mean Decrease in Gini, and root node appearance
  rates. Supports level-specific and attribute-level resolution.
- **Decision tree** (`method = "tree"`): CART classification tree
  revealing hierarchical decision structure. Root split identifies the
  gatekeeper attribute.
- **CRT/HierNet** (`method = "crt"`): L1-regularized logistic regression
  across a lambda grid. Lambda path, cross-validation, and permutation
  importance (MDA).
- **Nested marginal means** (`method = "nmm"`): sequential elimination
  procedure. Decisiveness ranking reveals the decision order.
- **Marginal R-squared** (`method = "marginal_r2"`): per-respondent
  per-attribute importance metric.

### Features

- Unified `cj_fit(formula, data, method)` interface for all methods.
- [`importance()`](https://dkarpa.github.io/cjdiag/reference/importance.md)
  generic with methods for all model types.
- Plot customization: `palette`, `base_size`, `label_wrap`,
  `attribute.names`, `level.names`, `group_by_attribute`, and full
  `theme` override.
- Three palettes: `"default"`, `"colorblind"` (Okabe-Ito), `"grey"`.
- Global options:
  [`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md),
  [`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md),
  [`get_cjdiag_options()`](https://dkarpa.github.io/cjdiag/reference/get_cjdiag_options.md).
- `tidy()` and `glance()` methods (conditional on broom/generics).
- Bundled `immig` dataset (Hainmueller & Hopkins 2015).
