test_that("code with no par()/options()/setwd() calls produces no finding", {
  result <- cl_check_option_restoration(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("a package with no R/ directory produces no finding", {
  result <- cl_check_option_restoration(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("unrestored par()/options()/setwd() changes are flagged; restored and query-only calls are not", {
  result <- cl_check_option_restoration(test_path("fixtures/code/option-restoration"))

  expect_equal(nrow(result), 4)
  expect_true(all(result$check == "option_restoration"))
  expect_true(all(result$file == "R/foo.R"))
  expect_true(all(as.character(result$severity) == "should_fix"))
  expect_setequal(result$line, c(2L, 13L, 26L, 33L))
})

test_that("restored, query-only, and no.readonly snapshot calls are not flagged", {
  result <- cl_check_option_restoration(test_path("fixtures/code/option-restoration"))
  expect_false(any(result$line %in% c(7L, 8L, 9L, 17L, 18L, 22L, 31L)))
})
