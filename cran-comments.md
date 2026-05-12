## Submission

This is a new package submission.

cjdiag provides diagnostic tools for conjoint survey experiments, complementing
existing AMCE-estimation packages (cjoint, cregg) with five methods for
diagnosing how respondents process attribute information: random forests,
CART decision trees, regularization-based attendance tests, nested marginal
means, and per-respondent marginal R-squared.

## Test environments

* Local: Windows 11, R 4.5.0
* GitHub Actions:
  - Ubuntu-latest (R devel, R release, R oldrel-1)
  - Windows-latest (R release)
  - macOS-latest (R release)
* win-builder devel: <https://win-builder.r-project.org/o4J91c740I27/>

## R CMD check results

0 errors | 0 warnings | 1 note (win-builder)

The single NOTE on win-builder lists possibly-misspelled words in
DESCRIPTION:

  Bansak, Bien, Breiman, Crepon, Hainmueller, Hangartner, Howlett,
  Jenke, Tibshirani

These are all author surnames cited in the methodological references
in the Description field (Bien & Tibshirani 2014; Breiman 2001; Dill,
Howlett & Mueller-Crepon 2024; Jenke, Bansak, Hainmueller & Hangartner
2021). They are spelled correctly.

## Reverse dependencies

This is a new release, so no reverse dependencies exist.

## Notes for reviewers

* All references in the Description field use the `<doi:...>` form and have
  been verified to resolve.
* The package depends on `randomForest` and `rpart` (Imports). hierNet,
  ggtext, and rpart.plot are in Suggests; functionality that requires them
  uses `requireNamespace()` guards and informative error messages.
* `method = "crt"` is computationally heavy and is wrapped in
  `\donttest{}` in examples; it is also tested behind
  `skip_if_not_installed("hierNet")`.
* The `immig` dataset (bundled) is the publicly available Hainmueller and
  Hopkins (2015) immigration conjoint, redistributed with permission via
  the `cjoint` package. It is used in tests, examples, and vignettes.
* No external network calls are made by tests or examples.
