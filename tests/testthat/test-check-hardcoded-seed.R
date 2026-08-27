test_that("code with no set.seed() calls produces no finding", {
  result <- cl_check_hardcoded_seed(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("literal seed values are flagged; a dynamic seed argument is not", {
  result <- cl_check_hardcoded_seed(test_path("fixtures/code/hardcoded-seed"))

  expect_equal(nrow(result), 4)
  expect_true(all(result$check == "hardcoded_seed"))
  expect_true(all(result$file == "R/foo.R"))
  expect_true(all(as.character(result$severity) == "should_fix"))
  expect_setequal(result$line, c(2L, 7L, 12L, 17L))
})

test_that("a package with no R/ directory produces no finding", {
  result <- cl_check_hardcoded_seed(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})
