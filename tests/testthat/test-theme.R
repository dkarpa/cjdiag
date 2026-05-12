# Tests for theme, palette, and options system

test_that("theme_cjdiag returns ggplot2 theme", {
  th <- theme_cjdiag()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
})

test_that("theme_cjdiag respects base_size", {
  th12 <- theme_cjdiag(base_size = 12)
  th16 <- theme_cjdiag(base_size = 16)
  expect_s3_class(th12, "theme")
  expect_s3_class(th16, "theme")
})

test_that("cjdiag_palette returns named vector", {
  pal <- cjdiag_palette("default")
  expect_length(pal, 3)
  expect_named(pal, c("primary", "secondary", "tertiary"))
  expect_equal(pal[["primary"]], "#2171b5")
})

test_that("cjdiag_palette supports colorblind and grey", {
  cb <- cjdiag_palette("colorblind")
  expect_equal(cb[["primary"]], "#0072B2")

  gr <- cjdiag_palette("grey")
  expect_equal(gr[["primary"]], "#525252")
})

test_that("cjdiag_palette rejects invalid names", {
  expect_error(cjdiag_palette("neon"))
})

test_that("set/get options round-trip works", {
  old <- set_cjdiag_theme(base_size = 16, palette = "colorblind")

  expect_equal(get_cjdiag_options("base_size"), 16)
  expect_equal(get_cjdiag_options("palette"), "colorblind")

  # Restore
  set_cjdiag_theme()
  expect_equal(get_cjdiag_options("base_size"), 12)
  expect_equal(get_cjdiag_options("palette"), "default")
})

test_that("set_cjdiag_labels stores and retrieves labels", {
  set_cjdiag_labels(attribute.names = c(Gender = "Sex"))
  opts <- get_cjdiag_options("labels")
  expect_equal(opts$attribute.names[["Gender"]], "Sex")

  # Reset
  set_cjdiag_labels(reset = TRUE)
  opts2 <- get_cjdiag_options("labels")
  expect_null(opts2$attribute.names)
})

test_that("set_cjdiag_labels merges with existing", {
  set_cjdiag_labels(reset = TRUE)
  set_cjdiag_labels(attribute.names = c(A = "A_renamed"))
  set_cjdiag_labels(attribute.names = c(B = "B_renamed"))
  opts <- get_cjdiag_options("labels")
  expect_equal(opts$attribute.names[["A"]], "A_renamed")
  expect_equal(opts$attribute.names[["B"]], "B_renamed")
  set_cjdiag_labels(reset = TRUE)
})

test_that(".resolve_plot_options respects priority order", {
  # Set global
  set_cjdiag_theme(base_size = 16)

  # Explicit arg overrides global
  opts <- .resolve_plot_options(base_size = 20)
  expect_equal(opts$base_size, 20)

  # Global overrides default
  opts2 <- .resolve_plot_options()
  expect_equal(opts2$base_size, 16)

  # Reset
  set_cjdiag_theme()
})

test_that(".apply_labels renames attributes and levels", {
  df <- data.frame(
    attribute = c("Gender", "Gender", "Edu"),
    level = c("male", "female", "college"),
    stringsAsFactors = FALSE
  )

  opts <- list(
    attribute.names = c(Gender = "Sex", Edu = "Education"),
    level.names = list(Gender = c(male = "Male", female = "Female"))
  )

  result <- .apply_labels(df, opts)
  expect_true(all(result$attribute[1:2] == "Sex"))
  expect_equal(result$attribute[3], "Education")
  expect_equal(result$level[1], "Male")
  expect_equal(result$level[2], "Female")
})
