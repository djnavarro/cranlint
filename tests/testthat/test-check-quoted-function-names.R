test_that("a quoted software name (not a function) produces no finding", {
  result <- cl_check_quoted_function_names(test_path("fixtures/desc/quoted-good"))
  expect_equal(nrow(result), 0)
})

test_that("a Description with no quoted words produces no finding", {
  result <- cl_check_quoted_function_names(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("a quoted base R function name is flagged", {
  result <- cl_check_quoted_function_names(test_path("fixtures/desc/quoted-function-name"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "quoted_function_names")
  expect_equal(result$file, "DESCRIPTION")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "should_fix")
  expect_match(result$message, "'summary'")
  expect_match(result$message, "base R function")
})

test_that("a quoted name matching the package's own function is flagged", {
  result <- cl_check_quoted_function_names(test_path("fixtures/desc/quoted-own-function-name"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "quoted_function_names")
  expect_match(result$message, "'do_good_things'")
  expect_match(result$message, "this package's own R/ files")
})
