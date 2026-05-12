# Tests for importance extraction

make_test_data <- function(n = 200) {
  set.seed(42)
  data.frame(
    choice = sample(0:1, n, replace = TRUE),
    gender = factor(sample(c("Male", "Female"), n, replace = TRUE)),
    edu    = factor(sample(c("High school", "College", "Graduate"), n, replace = TRUE)),
    job    = factor(sample(c("Lawyer", "Doctor", "Teacher"), n, replace = TRUE))
  )
}

test_that("importance() dispatches correctly for forest", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)
  imp <- importance(rf)

  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(imp$method, "forest")
  expect_equal(imp$resolution, "levels")
})

test_that("importance() dispatches correctly for tree", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)
  imp <- importance(tree)

  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(imp$method, "tree")
  expect_equal(imp$resolution, "levels")
})

test_that("importance.default errors for unknown class", {
  expect_error(
    importance(list()),
    "not defined"
  )
})

test_that("forest importance results match fit results", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)
  imp <- importance(rf)

  expect_equal(imp$results, rf$results)
  expect_equal(imp$oob_error, rf$oob_error)
  expect_equal(imp$ntree, rf$ntree)
})

test_that("tree importance results match fit results", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)
  imp <- importance(tree)

  expect_equal(imp$results, tree$results)
  expect_equal(imp$root_split, tree$root_split)
  expect_equal(imp$depth, tree$depth)
})

test_that("importance preserves resolution for attribute-level forest", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", resolution = "attributes",
               ntree = 50, seed = 42)
  imp <- importance(rf)

  expect_equal(imp$resolution, "attributes")
  expect_equal(nrow(imp$results), 3)
  expect_true(all(c("gender", "edu", "job") %in% imp$results$attribute))
  expect_false("level" %in% names(imp$results))
})

test_that("importance preserves resolution for attribute-level tree", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", resolution = "attributes",
                 cp = 0.01, seed = 42)
  imp <- importance(tree)

  expect_equal(imp$resolution, "attributes")
  expect_false("level" %in% names(imp$results))
})

test_that("importance print works", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)
  imp <- importance(rf)

  expect_output(print(imp), "Conjoint Importance Metrics")
  expect_output(print(imp), "Random Forest")
})

test_that("as.data.frame.cjdiag_importance works", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)
  imp <- importance(rf)
  result <- as.data.frame(imp)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(imp$results))
})

test_that("importance plot returns ggplot for forest", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)
  imp <- importance(rf)

  p1 <- plot(imp, type = "mda")
  expect_s3_class(p1, "ggplot")

  p2 <- plot(imp, type = "root")
  expect_s3_class(p2, "ggplot")

  p3 <- plot(imp, type = "combined")
  expect_s3_class(p3, "ggplot")
})

test_that("importance plot returns ggplot for tree", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)
  imp <- importance(tree)

  p1 <- plot(imp, type = "mda")
  expect_s3_class(p1, "ggplot")
})

test_that("importance plot errors for tree-incompatible types", {
  df <- make_test_data()
  tree <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "tree", cp = 0.01, seed = 42)
  imp <- importance(tree)

  expect_error(plot(imp, type = "root"), "only available for forest")
  expect_error(plot(imp, type = "combined"), "only available for forest")
})

# ---- Marginal R² resolution tests ----

make_test_data_with_resp <- function(n_resp = 20, n_tasks = 10) {
  set.seed(42)
  n <- n_resp * n_tasks
  data.frame(
    resp   = rep(seq_len(n_resp), each = n_tasks),
    choice = sample(0:1, n, replace = TRUE),
    gender = factor(sample(c("Male", "Female"), n, replace = TRUE)),
    edu    = factor(sample(c("High school", "College", "Graduate"), n, replace = TRUE)),
    job    = factor(sample(c("Lawyer", "Doctor", "Teacher"), n, replace = TRUE))
  )
}

test_that("importance preserves resolution for marginal_r2 (levels)", {
  df <- make_test_data_with_resp()
  mr2 <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "marginal_r2", resp_id = "resp",
                 resolution = "levels", seed = 42)
  imp <- importance(mr2)

  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(imp$method, "marginal_r2")
  expect_equal(imp$resolution, "levels")
  expect_true("level" %in% names(imp$results))
})

test_that("importance preserves resolution for marginal_r2 (attributes)", {
  df <- make_test_data_with_resp()
  mr2 <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "marginal_r2", resp_id = "resp",
                 resolution = "attributes", seed = 42)
  imp <- importance(mr2)

  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(imp$method, "marginal_r2")
  expect_equal(imp$resolution, "attributes")
  expect_false("level" %in% names(imp$results))
})
