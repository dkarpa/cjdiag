# Tests for decision tree method

make_test_data <- function(n = 200) {
  set.seed(42)
  data.frame(
    choice = sample(0:1, n, replace = TRUE),
    gender = factor(sample(c("Male", "Female"), n, replace = TRUE)),
    edu    = factor(sample(c("High school", "College", "Graduate"), n, replace = TRUE)),
    job    = factor(sample(c("Lawyer", "Doctor", "Teacher"), n, replace = TRUE))
  )
}

test_that("cj_fit with method='tree' returns cjdiag_tree", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  expect_s3_class(tree, "cjdiag_tree")
  expect_s3_class(tree, "cjdiag_fit")
  expect_equal(tree$method, "tree")
})

test_that("tree results tibble has expected columns", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  expected_cols <- c("rank", "attribute", "level", "importance", "var_name")
  expect_true(all(expected_cols %in% names(tree$results)))
})

test_that("tree root_split is a valid variable name", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  predictor_cols <- setdiff(names(cjdiag:::.prepare_data(
    choice ~ gender + edu + job, df)$dummy_data), ".outcome")

  # root_split should be a predictor or "<leaf>"
  expect_true(tree$root_split %in% c(predictor_cols, "<leaf>"))
})

test_that("tree depth and n_terminal are positive integers", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  expect_type(tree$depth, "integer")
  expect_type(tree$n_terminal, "integer")
  expect_true(tree$depth >= 0)
  expect_true(tree$n_terminal >= 1)
})

test_that("tree stores metadata correctly", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.005, seed = 123)

  expect_equal(tree$cp, 0.005)
  expect_equal(tree$seed, 123L)
  expect_equal(tree$outcome, "choice")
  expect_equal(sort(tree$attributes), c("edu", "gender", "job"))
  expect_equal(tree$n_obs, 200)
})

test_that("tree print works without error", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  expect_output(print(tree), "Conjoint Decision Tree")
  expect_output(print(tree), "Root split")
})

test_that("tree plot works with rpart.plot", {
  skip_if_not_installed("rpart.plot")

  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  # Should not error (plots to null device)
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  expect_invisible(plot(tree))
})

test_that("tree importance values are non-negative", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)

  expect_true(all(tree$results$importance >= 0))
})

test_that("tree is reproducible with same seed", {
  df <- make_test_data()
  tree1 <- cj_fit(choice ~ gender + edu + job, data = df,
                  method = "tree", cp = 0.01, seed = 42)
  tree2 <- cj_fit(choice ~ gender + edu + job, data = df,
                  method = "tree", cp = 0.01, seed = 42)

  expect_equal(tree1$results$importance, tree2$results$importance)
  expect_equal(tree1$root_split, tree2$root_split)
})

test_that("tree with high cp produces simple tree", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.5, seed = 42)

  # Very high cp should produce a very simple tree
  expect_true(tree$n_terminal <= 5)
})
