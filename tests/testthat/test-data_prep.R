# Tests for data preparation functions

test_that(".parse_formula extracts outcome and attributes", {
  df <- data.frame(y = c(0, 1), a = c("x", "y"), b = c("m", "n"))
  result <- cjdiag:::.parse_formula(y ~ a + b, df)

  expect_equal(result$outcome, "y")
  expect_equal(result$attributes, c("a", "b"))
})

test_that(".parse_formula errors on missing variables", {
  df <- data.frame(y = c(0, 1), a = c("x", "y"))

  expect_error(
    cjdiag:::.parse_formula(y ~ a + missing_var, df),
    "Variables not found"
  )
})

test_that(".parse_formula errors on non-formula input", {
  df <- data.frame(y = c(0, 1), a = c("x", "y"))

  expect_error(
    cjdiag:::.parse_formula("y ~ a", df),
    "must be a formula"
  )
})

test_that(".parse_formula errors on formula without response", {
  df <- data.frame(y = c(0, 1), a = c("x", "y"))

  expect_error(
    cjdiag:::.parse_formula(~ a, df),
    "must have both a response"
  )
})

test_that(".validate_outcome handles numeric 0/1", {
  df <- data.frame(y = c(0, 1, 0, 1), a = c("x", "y", "x", "y"))
  result <- cjdiag:::.validate_outcome(df, "y")
  expect_equal(result$y, c(0, 1, 0, 1))
})

test_that(".validate_outcome handles 2-level factor", {
  df <- data.frame(y = factor(c("no", "yes", "no", "yes")),
                   a = c("x", "y", "x", "y"))
  result <- cjdiag:::.validate_outcome(df, "y")
  expect_true(all(result$y %in% c(0, 1)))
})

test_that(".validate_outcome errors on non-binary numeric", {
  df <- data.frame(y = c(0, 1, 2), a = c("x", "y", "z"))
  expect_error(
    cjdiag:::.validate_outcome(df, "y"),
    "must be binary"
  )
})

test_that(".validate_outcome errors on 3-level factor", {
  df <- data.frame(y = factor(c("a", "b", "c")), x = 1:3)
  expect_error(
    cjdiag:::.validate_outcome(df, "y"),
    "must be binary"
  )
})

test_that(".validate_outcome handles logical", {
  df <- data.frame(y = c(TRUE, FALSE, TRUE), a = c("x", "y", "z"))
  result <- cjdiag:::.validate_outcome(df, "y")
  expect_equal(result$y, c(1L, 0L, 1L))
})

test_that(".validate_outcome removes NAs with warning", {
  df <- data.frame(y = c(0, NA, 1), a = c("x", "y", "z"))
  expect_warning(
    result <- cjdiag:::.validate_outcome(df, "y"),
    "NA values"
  )
  expect_equal(nrow(result), 2)
})

test_that(".validate_attributes converts to factor", {
  df <- data.frame(y = 0:1, a = c("x", "y"), b = c("m", "n"))
  result <- cjdiag:::.validate_attributes(df, c("a", "b"))
  expect_true(is.factor(result$a))
  expect_true(is.factor(result$b))
})

test_that(".validate_attributes warns on single-level factor", {
  df <- data.frame(y = 0:1, a = c("x", "x"))
  expect_warning(
    cjdiag:::.validate_attributes(df, "a"),
    "only 1 level"
  )
})

test_that(".validate_attributes drops unused levels", {
  df <- data.frame(y = 0:1, a = factor(c("x", "y"), levels = c("x", "y", "z")))
  result <- cjdiag:::.validate_attributes(df, "a")
  expect_equal(nlevels(result$a), 2)
})

test_that(".make_dummies produces correct number of columns", {
  df <- data.frame(
    y = c(0, 1, 0, 1, 0, 1),
    a = factor(c("x", "y", "x", "y", "x", "y")),
    b = factor(c("m", "n", "o", "m", "n", "o"))
  )
  result <- cjdiag:::.make_dummies(df, "y", c("a", "b"))

  # 2 levels for a + 3 levels for b = 5 dummy cols + 1 outcome = 6
  expect_equal(ncol(result$dummy_data), 6)
  expect_equal(nrow(result$attr_map), 5)
})

test_that(".create_attr_map correctly maps with prefix-similar names", {
  # This tests the fix for the Job/JobPlans prefix collision bug
  df <- data.frame(
    y = rep(0:1, 6),
    Job = factor(rep(c("Lawyer", "Doctor"), 6)),
    JobPlans = factor(rep(c("Has plans", "No plans"), each = 6))
  )
  result <- cjdiag:::.make_dummies(df, "y", c("Job", "JobPlans"))
  attr_map <- result$attr_map

  # Job columns should map to "Job", not "JobPlans"
  job_rows <- attr_map[attr_map$attribute == "Job", ]
  expect_equal(nrow(job_rows), 2)
  expect_true(all(job_rows$level %in% c("Lawyer", "Doctor")))

  # JobPlans columns should map to "JobPlans"
  jp_rows <- attr_map[attr_map$attribute == "JobPlans", ]
  expect_equal(nrow(jp_rows), 2)
  expect_true(all(jp_rows$level %in% c("Has plans", "No plans")))
})

test_that(".prepare_data returns complete prep object", {
  df <- data.frame(
    y = c(0, 1, 0, 1, 0, 1),
    a = c("x", "y", "x", "y", "x", "y"),
    b = c("m", "n", "m", "n", "m", "n")
  )
  result <- cjdiag:::.prepare_data(y ~ a + b, df)

  expect_type(result, "list")
  expect_true(all(c("dummy_data", "outcome", "attributes", "attr_map",
                     "n_obs", "n_levels", "formula") %in% names(result)))
  expect_equal(result$outcome, "y")
  expect_equal(result$attributes, c("a", "b"))
  expect_equal(result$n_obs, 6)
  expect_equal(result$n_levels, 4)  # 2 + 2
  expect_s3_class(result$formula, "formula")
})
