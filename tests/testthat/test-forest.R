# Tests for random forest method

# Create reproducible test data
make_test_data <- function(n = 200) {
  set.seed(42)
  data.frame(
    choice = sample(0:1, n, replace = TRUE),
    gender = factor(sample(c("Male", "Female"), n, replace = TRUE)),
    edu    = factor(sample(c("High school", "College", "Graduate"), n, replace = TRUE)),
    job    = factor(sample(c("Lawyer", "Doctor", "Teacher"), n, replace = TRUE))
  )
}

test_that("cj_fit with method='forest' returns cjdiag_forest", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expect_s3_class(rf, "cjdiag_forest")
  expect_s3_class(rf, "cjdiag_fit")
  expect_equal(rf$method, "forest")
})

test_that("forest results tibble has expected columns", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expected_cols <- c("rank", "attribute", "level", "mda", "mdg",
                     "root_pct", "class_0", "class_1", "var_name")
  expect_true(all(expected_cols %in% names(rf$results)))
})

test_that("forest results have correct number of rows", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  # 2 (gender) + 3 (edu) + 3 (job) = 8 levels
  expect_equal(nrow(rf$results), 8)
})

test_that("forest MDA values are numeric", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expect_type(rf$results$mda, "double")
  expect_type(rf$results$mdg, "double")
})

test_that("forest root_pct sums to approximately 100", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  total_root <- sum(rf$results$root_pct)
  expect_true(abs(total_root - 100) < 1)
})

test_that("forest OOB error is between 0 and 1", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expect_true(rf$oob_error >= 0 && rf$oob_error <= 1)
})

test_that("forest stores metadata correctly", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 100, seed = 123)

  expect_equal(rf$ntree, 100L)
  expect_equal(rf$seed, 123L)
  expect_equal(rf$outcome, "choice")
  expect_equal(sort(rf$attributes), c("edu", "gender", "job"))
  expect_equal(rf$n_obs, 200)
  expect_equal(rf$n_levels, 8)
})

test_that("forest print works without error", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expect_output(print(rf), "Conjoint Random Forest")
  expect_output(print(rf), "OOB Error")
})

test_that("forest plot returns ggplot object", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  p <- plot(rf, type = "importance")
  expect_s3_class(p, "ggplot")

  p2 <- plot(rf, type = "combined")
  expect_s3_class(p2, "ggplot")

  p3 <- plot(rf, type = "rank")
  expect_s3_class(p3, "ggplot")
})

test_that("forest is reproducible with same seed", {
  df <- make_test_data()
  rf1 <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "forest", ntree = 50, seed = 42)
  rf2 <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "forest", ntree = 50, seed = 42)

  expect_equal(rf1$results$mda, rf2$results$mda)
  expect_equal(rf1$oob_error, rf2$oob_error)
})

test_that("forest root_dist is a tibble", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expect_s3_class(rf$root_dist, "tbl_df")
  expect_true(all(c("level", "count", "pct") %in% names(rf$root_dist)))
})

test_that("forest attr_map has complete mapping", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df,
               method = "forest", ntree = 50, seed = 42)

  expect_false(any(is.na(rf$attr_map$attribute)))
  expect_false(any(is.na(rf$attr_map$level)))
  expect_equal(nrow(rf$attr_map), 8)
})
