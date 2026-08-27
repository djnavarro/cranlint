test_that("no-argument call returns a well-typed zero-row tibble", {
  result <- .cl_new_result()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_equal(
    names(result),
    c("check", "file", "line", "severity", "message", "policy_reference")
  )
  expect_type(result$check, "character")
  expect_type(result$file, "character")
  expect_type(result$line, "integer")
  expect_s3_class(result$severity, "ordered")
  expect_type(result$message, "character")
  expect_type(result$policy_reference, "character")
})

test_that("populated call returns expected values", {
  result <- .cl_new_result(
    check = "hardcoded_seed",
    file = "R/foo.R",
    line = 10L,
    severity = "must_fix",
    message = "set.seed(1) found in package code",
    policy_reference = "https://contributor.r-project.org/cran-cookbook/"
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "hardcoded_seed")
  expect_equal(result$file, "R/foo.R")
  expect_equal(result$line, 10L)
  expect_equal(as.character(result$severity), "must_fix")
  expect_equal(
    result$policy_reference,
    "https://contributor.r-project.org/cran-cookbook/"
  )
})

test_that("severity is an ordered factor with the correct level order", {
  result <- .cl_new_result(
    check = "some_check",
    file = "R/foo.R",
    line = 1L,
    severity = "should_fix",
    message = "an issue",
    policy_reference = "https://contributor.r-project.org/cran-cookbook/"
  )
  expect_equal(levels(result$severity), c("advisory", "should_fix", "must_fix"))
  expect_true(result$severity[1] > "advisory")
  expect_true(result$severity[1] < "must_fix")
})

test_that("invalid severity values raise an informative error", {
  expect_error(
    .cl_new_result(severity = "critical"),
    "Invalid `severity` value"
  )
})

test_that("scalar arguments recycle to the length of vector arguments", {
  result <- .cl_new_result(
    check = "hardcoded_seed",
    file = "R/foo.R",
    line = c(10L, 20L),
    severity = "advisory",
    message = c("first instance", "second instance"),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/"
  )

  expect_equal(nrow(result), 2)
  expect_equal(result$check, c("hardcoded_seed", "hardcoded_seed"))
  expect_equal(result$line, c(10L, 20L))
})

test_that("NA_integer_ line is allowed for findings without a specific line", {
  result <- .cl_new_result(
    check = "description_length",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "advisory",
    message = "Description field is a single short sentence",
    policy_reference = "https://contributor.r-project.org/cran-cookbook/"
  )

  expect_true(is.na(result$line))
})
