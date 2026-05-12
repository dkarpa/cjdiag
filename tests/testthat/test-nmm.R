# Tests for Nested Marginal Means method

# Create reproducible test data
make_nmm_data <- function(n_resp = 50, n_tasks = 5) {
  set.seed(42)
  n <- n_resp * n_tasks * 2
  data.frame(
    resp_id = rep(1:n_resp, each = n_tasks * 2),
    contest_no = rep(rep(1:n_tasks, each = 2), n_resp),
    choice = sample(0:1, n, replace = TRUE),
    gender = factor(sample(c("Male", "Female"), n, replace = TRUE)),
    edu = factor(sample(c("HS", "College", "Grad"), n, replace = TRUE)),
    job = factor(sample(c("Lawyer", "Doctor", "Teacher"), n, replace = TRUE))
  )
}

test_that("cj_fit with method='nmm' returns cjdiag_nmm", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  expect_s3_class(nmm, "cjdiag_nmm")
  expect_s3_class(nmm, "cjdiag_fit")
  expect_equal(nmm$method, "nmm")
})

test_that("nmm results tibble has expected columns", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  expected_cols <- c("rank", "attribute", "level", "mm", "decisiveness",
                     "pct_of_total", "cumulative_pct", "var_name")
  expect_true(all(expected_cols %in% names(nmm$results)))
})

test_that("nmm results have correct number of rows", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  # 2 (gender) + 3 (edu) + 3 (job) = 8 levels
  expect_equal(nrow(nmm$results), 8)
})

test_that("nmm cumulative_pct is non-decreasing", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  cpct <- nmm$results$cumulative_pct
  expect_true(all(diff(cpct) >= -1e-10))
})

test_that("nmm sample_history is non-increasing", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  sh <- nmm$sample_history
  expect_true(all(diff(sh) <= 0))
})

test_that("nmm resolution='attributes' raises error", {
  df <- make_nmm_data()
  expect_error(
    cj_fit(choice ~ gender + edu + job, data = df,
           method = "nmm", resp_id = "resp_id", resolution = "attributes"),
    "only supports"
  )
})

test_that("nmm without resp_id raises error", {
  df <- make_nmm_data()
  expect_error(
    cj_fit(choice ~ gender + edu + job, data = df, method = "nmm"),
    "resp_id"
  )
})

test_that("importance.cjdiag_nmm works", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  imp <- importance(nmm)
  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(imp$method, "nmm")
})

test_that("nmm print works without error", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  expect_output(print(nmm), "Nested Marginal Means")
  expect_output(print(nmm), "Total pairs")
})

test_that("nmm plot returns a ggplot object", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id")

  p <- plot(nmm)
  expect_s3_class(p, "ggplot")
})

test_that("nmm bootstrap adds CI columns", {
  df <- make_nmm_data()
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                method = "nmm", resp_id = "resp_id", n_boot = 5)

  expect_equal(nmm$n_boot, 5L)
  expect_true(any(!is.na(nmm$results$q025)))
  expect_true(any(!is.na(nmm$results$q975)))
})

test_that("nmm data prep handles missing task column", {
  set.seed(42)
  n <- 100
  df <- data.frame(
    resp_id = rep(1:25, each = 4),
    choice = sample(0:1, n, replace = TRUE),
    attr_a = factor(sample(c("x", "y"), n, replace = TRUE)),
    attr_b = factor(sample(c("p", "q", "r"), n, replace = TRUE))
  )

  # No contest_no column — should infer pairs from consecutive rows
  nmm <- cj_fit(choice ~ attr_a + attr_b, data = df,
                method = "nmm", resp_id = "resp_id")

  expect_s3_class(nmm, "cjdiag_nmm")
  expect_true(nrow(nmm$results) > 0)
})
