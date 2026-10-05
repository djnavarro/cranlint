test_that("an exported function with no \\value tag is flagged", {
  skip_if_not_installed("checkhelper")

  result <- cl_check_missing_value(test_path("fixtures/missing-value/missing"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "missing_value")
  expect_equal(result$file, "man/foo.Rd")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "must_fix")
  expect_match(result$message, "`foo`")
})

test_that("an exported function with a \\value tag produces no finding", {
  skip_if_not_installed("checkhelper")

  result <- cl_check_missing_value(test_path("fixtures/missing-value/documented"))
  expect_equal(nrow(result), 0)
})

test_that("a package with no R/ directory produces no finding", {
  skip_if_not_installed("checkhelper")

  result <- cl_check_missing_value(test_path("fixtures/missing-value/no-r-dir"))
  expect_equal(nrow(result), 0)
})

test_that("the source package is left untouched", {
  skip_if_not_installed("checkhelper")

  pkg_dir <- test_path("fixtures/missing-value/missing")
  before <- list.files(pkg_dir, recursive = TRUE, all.files = TRUE)

  cl_check_missing_value(pkg_dir)

  after <- list.files(pkg_dir, recursive = TRUE, all.files = TRUE)
  expect_equal(after, before)
})

test_that("a missing checkhelper installation errors with a classed condition", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  expect_error(
    cl_check_missing_value(test_path("fixtures/missing-value/missing")),
    class = "cranlint_missing_checkhelper"
  )
})
