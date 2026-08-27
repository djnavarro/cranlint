test_that("code with no print()/cat() calls produces no finding", {
  result <- cl_check_verbose_output(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("a package with no R/ directory produces no finding", {
  result <- cl_check_verbose_output(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("print()/cat() outside an S3 method is flagged, including top-level and anonymous-nested calls", {
  result <- cl_check_verbose_output(test_path("fixtures/code/verbose-output"))

  expect_equal(nrow(result), 4)
  expect_true(all(result$check == "verbose_output"))
  expect_true(all(result$file == "R/foo.R"))
  expect_true(all(as.character(result$severity) == "should_fix"))
  expect_setequal(result$line, c(2L, 3L, 7L, 25L))
})

test_that("print()/cat() inside print/format/summary S3 methods is not flagged", {
  result <- cl_check_verbose_output(test_path("fixtures/code/verbose-output"))
  expect_false(any(result$line %in% c(11L, 16L, 21L)))
})
