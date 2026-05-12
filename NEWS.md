# cjdiag (development)

## New features

* `plot(crt_obj, type = "rank")` — connected-dot survival ranking. Each
  level's max-lambda survival statistic plotted in descending order,
  matching the package's forest `type = "rank"` aesthetic.

# cjdiag 0.2.1

Focuses the package on a smaller set of well-supported plots and rewrites
the README around the random-forest results table.

## Breaking changes

* Removed `plot(tree_obj, type = "importance")`. Decision trees are
  rendered via `rpart.plot` only; the bar chart of rpart variable
  importance was removed because the tree itself is the diagnostic and
  the bar chart was misleading at level resolution.
* Removed `plot(nmm_obj, type = "decisiveness")` and
  `plot(nmm_obj, type = "sample")`. Nested marginal means now plots the
  cumulative-explanation curve only. The underlying `decisiveness` and
  `sample_history` columns are still available on the fit object.

## Improvements

* Cumulative and rank plots now place each label at its own rotated
  x-axis tick, so collisions are impossible by construction and no
  labels are dropped. Tick labels show the attribute on top in black
  and the level below in dark grey, separated by a line break, via
  `ggtext::geom_richtext()` (with a plain rotated-text fallback if
  ggtext is unavailable). The bottom plot margin scales dynamically
  with the longest label.
* Decision tree plots replace the dummy-name labels (e.g.
  `JobPlansno.plans.to.look.for.work`) with `attribute: level` (e.g.
  `JobPlans: no plans to look for work`) via a custom `split.fun`
  driven by the fit's `attr_map`. Works for any conjoint data without
  per-dataset configuration.
* README: random-forest example shows the full results table via
  `knitr::kable()` with column-by-column explanations of `mda`,
  `root_pct`, `class_0`, and `class_1`. Importance plot switched from
  bar chart to the rank plot.
* README and Getting Started vignette now include an Estimands Table
  (estimand / `method =` / question / output / behavioural assumption /
  when to use) so users can pick a method without reading the docs.
* The single Introduction vignette is replaced by a Getting Started
  overview (`cjdiag.Rmd`) plus one task-oriented vignette per method
  (`forest`, `tree`, `nmm`, `marginal_r2`, `crt`).
* Plot help pages now share an `@family plotting` block so the help
  pages cross-link.
* README: added ERC AGAPP funding acknowledgement.

# cjdiag 0.2.0

Initial CRAN release.

## Methods

* **Random forest** (`method = "forest"`): attribute importance via Mean
  Decrease in Accuracy, Mean Decrease in Gini, and root node appearance
  rates. Supports level-specific and attribute-level resolution.
* **Decision tree** (`method = "tree"`): CART classification tree revealing
  hierarchical decision structure. Root split identifies the gatekeeper
  attribute.
* **CRT/HierNet** (`method = "crt"`): L1-regularized logistic regression
  across a lambda grid. Lambda path, cross-validation, and permutation
  importance (MDA).
* **Nested marginal means** (`method = "nmm"`): sequential elimination
  procedure. Decisiveness ranking reveals the decision order.
* **Marginal R-squared** (`method = "marginal_r2"`): per-respondent
  per-attribute importance metric.

## Features

* Unified `cj_fit(formula, data, method)` interface for all methods.
* `importance()` generic with methods for all model types.
* Plot customization: `palette`, `base_size`, `label_wrap`,
  `attribute.names`, `level.names`, `group_by_attribute`, and full
  `theme` override.
* Three palettes: `"default"`, `"colorblind"` (Okabe-Ito), `"grey"`.
* Global options: `set_cjdiag_theme()`, `set_cjdiag_labels()`,
  `get_cjdiag_options()`.
* `tidy()` and `glance()` methods (conditional on broom/generics).
* Bundled `immig` dataset (Hainmueller & Hopkins 2015).
