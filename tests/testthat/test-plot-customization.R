# Tests for plot customization parameters

# Shared test data
make_test_data <- function(n = 400) {
  set.seed(42)
  data.frame(
    choice = sample(0:1, n, replace = TRUE),
    gender = factor(sample(c("male", "female"), n, replace = TRUE)),
    edu = factor(sample(c("hs", "ba", "ma"), n, replace = TRUE)),
    job = factor(sample(c("cook", "nurse", "engineer"), n, replace = TRUE)),
    stringsAsFactors = FALSE
  )
}

test_that("forest plot accepts customization params", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df, method = "forest")

  # Default plot
  p1 <- plot(rf)
  expect_s3_class(p1, "ggplot")

  # Custom palette
  p2 <- plot(rf, palette = "colorblind")
  expect_s3_class(p2, "ggplot")

  # Custom base_size
  p3 <- plot(rf, base_size = 16)
  expect_s3_class(p3, "ggplot")

  # Custom label_wrap
  p4 <- plot(rf, label_wrap = 20)
  expect_s3_class(p4, "ggplot")

  # Attribute renaming
  p5 <- plot(rf, attribute.names = c(gender = "Sex"))
  expect_s3_class(p5, "ggplot")
})

test_that("forest combined and rank plots accept opts", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df, method = "forest")

  p1 <- plot(rf, type = "combined", palette = "grey")
  expect_s3_class(p1, "ggplot")

  p2 <- plot(rf, type = "rank", palette = "colorblind")
  expect_s3_class(p2, "ggplot")
})

test_that("tree plot returns invisible NULL", {
  skip_if_not_installed("rpart.plot")
  df <- make_test_data()
  tr <- cj_fit(choice ~ gender + edu + job, data = df, method = "tree")

  result <- plot(tr)
  expect_null(result)
})

test_that("nmm plot returns ggplot", {
  df <- make_test_data()
  df$resp_id <- rep(1:(nrow(df)/2), each = 2)
  nmm <- cj_fit(choice ~ gender + edu + job, data = df,
                 method = "nmm", resp_id = "resp_id")

  p <- plot(nmm)
  expect_s3_class(p, "ggplot")
})

test_that("group_by_attribute works in forest importance plot", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df, method = "forest")

  p <- plot(rf, group_by_attribute = TRUE)
  expect_s3_class(p, "ggplot")
  # Check that faceting is applied
  expect_true("FacetGrid" %in% class(p$facet))
})

test_that("global options affect plots", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df, method = "forest")

  set_cjdiag_theme(palette = "colorblind")
  p <- plot(rf)
  expect_s3_class(p, "ggplot")

  # Reset
  set_cjdiag_theme()
})

test_that("global labels propagate to plots", {
  df <- make_test_data()
  rf <- cj_fit(choice ~ gender + edu + job, data = df, method = "forest")

  set_cjdiag_labels(attribute.names = c(gender = "Sex"))
  p <- plot(rf)
  expect_s3_class(p, "ggplot")

  # Reset
  set_cjdiag_labels(reset = TRUE)
})
