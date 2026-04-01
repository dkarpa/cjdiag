# cjdiag: Diagnostic Tools for Conjoint Survey Experiments

Tools for attribute-level importance and attendance in conjoint survey
experiments — which attribute levels drive choices, how they rank, and
which ones respondents ignore.

## Entry Points

- [`cj_fit()`](https://dkarpa.github.io/cjdiag/reference/cj_fit.md) —
  Fits one of 5 methods: `"forest"`, `"tree"`, `"crt"`, `"nmm"`,
  `"marginal_r2"`

## Common Workflow

    # 1. Fit a model
    rf <- cj_fit(outcome ~ attr1 + attr2, data = df, method = "forest")

    # 2. View results
    print(rf)
    importance(rf)

    # 3. Visualize
    plot(rf)
    plot(rf, palette = "colorblind", group_by_attribute = TRUE)

## Customization

All plot methods support `base_size`, `colors`, `palette`, `theme`,
`label_wrap`, `attribute.names`, and `level.names` parameters. Use
[`set_cjdiag_theme()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_theme.md)
and
[`set_cjdiag_labels()`](https://dkarpa.github.io/cjdiag/reference/set_cjdiag_labels.md)
to set global defaults.

## Author

**Maintainer**: David Karpa <davidfkarpa@gmail.com>
