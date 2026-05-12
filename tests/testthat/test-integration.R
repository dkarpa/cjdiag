# Integration tests with real conjoint datasets

# Helper to load immigration data
load_immigration_data <- function() {
  skip_if_not_installed("cjoint")

  data("immigrationconjoint", package = "cjoint", envir = environment())
  df <- immigrationconjoint

  # Rename columns with spaces (matching 01_rpart_rf_analysis.R)
  rename_map <- c(
    "Language Skills"        = "LanguageSkills",
    "Country of Origin"      = "CountryOfOrigin",
    "Job Experience"         = "JobExperience",
    "Job Plans"              = "JobPlans",
    "Reason for Application" = "ReasonForApplication",
    "Prior Entry"            = "PriorEntry"
  )
  for (old_name in names(rename_map)) {
    if (old_name %in% names(df)) {
      names(df)[names(df) == old_name] <- rename_map[old_name]
    }
  }

  df$Chosen_Immigrant <- as.numeric(as.character(df$Chosen_Immigrant))
  df
}

# Helper to load candidate data
load_candidate_data <- function() {
  skip_if_not_installed("haven")

  candidate_path <- file.path(
    testthat::test_path(), "..", "..", "..", "HHY14", "candidate.dta"
  )
  if (!file.exists(candidate_path)) {
    skip("Candidate data not available")
  }

  df <- haven::read_dta(candidate_path)
  df <- as.data.frame(df)

  # Convert haven_labelled columns to factors
  for (col in names(df)) {
    if (inherits(df[[col]], "haven_labelled")) {
      df[[col]] <- haven::as_factor(df[[col]])
    }
  }

  df
}


# ---- Immigration Conjoint Tests ----

test_that("full pipeline works with immigration data (forest)", {
  df <- load_immigration_data()

  rf <- cj_fit(
    Chosen_Immigrant ~ Gender + Education + LanguageSkills +
      CountryOfOrigin + Job + JobExperience + JobPlans +
      ReasonForApplication + PriorEntry,
    data = df,
    method = "forest",
    ntree = 100,
    seed = 42
  )

  expect_s3_class(rf, "cjdiag_forest")
  expect_equal(rf$n_obs, nrow(df))
  expect_equal(length(rf$attributes), 9)

  # Verify results are sensible
  expect_true(nrow(rf$results) > 40)  # ~50 levels
  expect_true(rf$oob_error > 0 && rf$oob_error < 0.5)

  # Top MDA level should be Plans-related (strong signal)
  top_attr <- rf$results$attribute[1]
  expect_true(top_attr %in% c("JobPlans", "LanguageSkills", "Education"))

  # importance() works

  imp <- importance(rf)
  expect_s3_class(imp, "cjdiag_importance")
  expect_equal(nrow(imp$results), nrow(rf$results))
})

test_that("full pipeline works with immigration data (tree)", {
  df <- load_immigration_data()

  tree <- cj_fit(
    Chosen_Immigrant ~ Gender + Education + LanguageSkills +
      CountryOfOrigin + Job + JobExperience + JobPlans +
      ReasonForApplication + PriorEntry,
    data = df,
    method = "tree",
    cp = 0.005,
    seed = 42
  )

  expect_s3_class(tree, "cjdiag_tree")
  expect_equal(tree$n_obs, nrow(df))

  # Root split should be a meaningful attribute
  expect_true(tree$root_split != "<leaf>")
  expect_true(tree$depth >= 2)
  expect_true(tree$n_terminal >= 3)

  # importance() works
  imp <- importance(tree)
  expect_s3_class(imp, "cjdiag_importance")
})

test_that("all forest plot types work with immigration data", {
  df <- load_immigration_data()

  rf <- cj_fit(
    Chosen_Immigrant ~ Gender + Education + LanguageSkills +
      CountryOfOrigin + Job + JobExperience + JobPlans +
      ReasonForApplication + PriorEntry,
    data = df,
    method = "forest",
    ntree = 50,
    seed = 42
  )

  p1 <- plot(rf, type = "importance", top_n = 15)
  expect_s3_class(p1, "ggplot")

  p2 <- plot(rf, type = "combined", top_n = 15)
  expect_s3_class(p2, "ggplot")

  p3 <- plot(rf, type = "rank", top_n = 15)
  expect_s3_class(p3, "ggplot")

  # Importance plots
  imp <- importance(rf)
  p4 <- plot(imp, type = "mda")
  expect_s3_class(p4, "ggplot")

  p5 <- plot(imp, type = "root")
  expect_s3_class(p5, "ggplot")

  p6 <- plot(imp, type = "combined")
  expect_s3_class(p6, "ggplot")
})

test_that("reproducibility: same seed gives identical results", {
  df <- load_immigration_data()

  rf1 <- cj_fit(
    Chosen_Immigrant ~ Gender + Education + LanguageSkills +
      CountryOfOrigin + Job + JobExperience + JobPlans +
      ReasonForApplication + PriorEntry,
    data = df,
    method = "forest",
    ntree = 50,
    seed = 42
  )

  rf2 <- cj_fit(
    Chosen_Immigrant ~ Gender + Education + LanguageSkills +
      CountryOfOrigin + Job + JobExperience + JobPlans +
      ReasonForApplication + PriorEntry,
    data = df,
    method = "forest",
    ntree = 50,
    seed = 42
  )

  expect_equal(rf1$results$mda, rf2$results$mda)
  expect_equal(rf1$results$root_pct, rf2$results$root_pct)
  expect_equal(rf1$oob_error, rf2$oob_error)
})


# ---- Candidate Conjoint Tests ----

test_that("full pipeline works with candidate data (forest)", {
  df <- load_candidate_data()

  # Identify attribute columns (excluding metadata)
  skip_if(!all(c("Y", "College", "Profession", "Age") %in% names(df)),
          "Expected columns not found in candidate data")

  attrs <- intersect(
    c("College", "Profession", "Age", "Military", "Religion",
      "Gender", "Income", "FamilyRace"),
    names(df)
  )

  formula_str <- paste("Y ~", paste(attrs, collapse = " + "))

  rf <- cj_fit(
    stats::as.formula(formula_str),
    data = df,
    method = "forest",
    ntree = 100,
    seed = 42
  )

  expect_s3_class(rf, "cjdiag_forest")
  expect_true(nrow(rf$results) > 20)
  expect_true(rf$oob_error > 0 && rf$oob_error < 0.5)

  imp <- importance(rf)
  expect_equal(nrow(imp$results), nrow(rf$results))
})

test_that("full pipeline works with candidate data (tree)", {
  df <- load_candidate_data()

  skip_if(!all(c("Y", "College", "Profession", "Age") %in% names(df)),
          "Expected columns not found in candidate data")

  attrs <- intersect(
    c("College", "Profession", "Age", "Military", "Religion",
      "Gender", "Income", "FamilyRace"),
    names(df)
  )

  formula_str <- paste("Y ~", paste(attrs, collapse = " + "))

  tree <- cj_fit(
    stats::as.formula(formula_str),
    data = df,
    method = "tree",
    cp = 0.005,
    seed = 42
  )

  expect_s3_class(tree, "cjdiag_tree")
  expect_true(tree$root_split != "<leaf>")
})


# ---- Edge Cases ----

test_that("cj_fit errors on empty data", {
  df <- data.frame(y = integer(0), a = character(0))
  expect_error(cj_fit(y ~ a, data = df), "no rows")
})

test_that("cj_fit errors on non-dataframe input", {
  expect_error(cj_fit(y ~ a, data = list()), "must be a data frame")
})

test_that("cj_fit errors on invalid method", {
  df <- data.frame(y = 0:1, a = c("x", "y"))
  expect_error(cj_fit(y ~ a, data = df, method = "invalid"))
})
