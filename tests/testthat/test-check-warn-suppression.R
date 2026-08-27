test_that("code with no options(warn = <negative>) produces no finding", {
  result <- cl_check_warn_suppression(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("negative warn values are flagged; positive ones are not", {
  result <- cl_check_warn_suppression(test_path("fixtures/code/warn-suppression"))

  expect_equal(nrow(result), 2)
  expect_true(all(result$check == "warn_suppression"))
  expect_true(all(result$file == "R/foo.R"))
  expect_true(all(as.character(result$severity) == "must_fix"))
  expect_setequal(result$line, c(2L, 7L))
})

test_that("a package with no R/ directory produces no finding", {
  result <- cl_check_warn_suppression(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})
