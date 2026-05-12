# Tests for CRT/HierNet method

# Skip all CRT tests if hierNet is not installed
skip_if_no_crt <- function() {
  testthat::skip_if_not_installed("hierNet")
}

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

test_that("cj_fit with method='crt' returns cjdiag_crt", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  expect_s3_class(crt, "cjdiag_crt")
  expect_s3_class(crt, "cjdiag_fit")
  expect_equal(crt$method, "crt")
})

test_that("crt results tibble has expected columns", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  expected_cols <- c("rank", "attribute", "level", "mda", "coefficient",
                     "abs_coefficient", "max_lambda",
                     "attended", "var_name")
  expect_true(all(expected_cols %in% names(crt$results)))
})

test_that("crt results have correct number of rows", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  # 2 (gender) + 3 (edu) + 3 (job) = 8 levels
  expect_equal(nrow(crt$results), 8)
})

test_that("crt resolution='attributes' raises error", {
  df <- make_test_data()
  expect_error(
    cj_fit(choice ~ gender + edu + job, data = df,
           method = "crt", resolution = "attributes"),
    "only supports"
  )
})

test_that("importance.cjdiag_crt works", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  imp <- importance(crt)
  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(imp$method, "crt")
  expect_true(!is.null(imp$optimal_lambda))
  expect_true(!is.null(imp$n_attended))
})

test_that("crt print works without error", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  expect_output(print(crt), "Conjoint CRT/HierNet Model")
  expect_output(print(crt), "Optimal lambda")
})

test_that("crt plot types return ggplot objects", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  p1 <- plot(crt, type = "robustness")
  expect_s3_class(p1, "ggplot")

  p2 <- plot(crt, type = "survival")
  expect_s3_class(p2, "ggplot")

  p3 <- plot(crt, type = "mda")
  expect_s3_class(p3, "ggplot")

  p4 <- plot(crt, type = "cv")
  expect_s3_class(p4, "ggplot")

  p5 <- plot(crt, type = "rank")
  expect_s3_class(p5, "ggplot")
})

test_that("crt cv_results has expected structure", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  expect_equal(nrow(crt$cv_results), 2)
  expect_true(all(c("lambda", "mean_deviance", "sd_deviance") %in%
                    names(crt$cv_results)))
})

test_that("crt path_coefs matrix has correct dimensions", {
  skip_if_no_crt()
  df <- make_test_data()
  crt <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "crt", lambda_grid = c(5, 10),
                n_folds = 2, n_perm = 2, seed = 42)

  expect_equal(nrow(crt$path_coefs), 8)  # 8 levels
  expect_equal(ncol(crt$path_coefs), 2)  # 2 lambdas
})

test_that("augment_profile_order doubles data correctly", {
  df <- data.frame(
    Y = c(1, 0, 1),
    A_left = c("a", "b", "c"),
    A_right = c("d", "e", "f"),
    stringsAsFactors = FALSE
  )

  result <- augment_profile_order(df, "Y", "A_left", "A_right")

  expect_equal(nrow(result), 6)
  # Outcome is inverted in second half
  expect_equal(result$Y[4:6], 1 - df$Y)
  # Columns are swapped in second half
  expect_equal(result$A_left[4:6], df$A_right)
  expect_equal(result$A_right[4:6], df$A_left)
})

test_that("augment_profile_order validates inputs", {
  df <- data.frame(Y = c(1, 0), A = c("a", "b"))

  expect_error(augment_profile_order(df, "Y", c("A", "B"), "A"),
               "same length")
  expect_error(augment_profile_order(df, "missing", "A", "A"),
               "not found")
  expect_error(augment_profile_order("not_df", "Y", "A", "A"),
               "data frame")
})
