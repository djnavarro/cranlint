test_that("code with no installed.packages() call produces no finding", {
  result <- cl_check_installed_packages(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("installed.packages() is flagged; requireNamespace() is not", {
  result <- cl_check_installed_packages(test_path("fixtures/code/installed-packages"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "installed_packages")
  expect_equal(result$file, "R/foo.R")
  expect_equal(result$line, 2L)
  expect_equal(as.character(result$severity), "should_fix")
})

test_that("a package with no R/ directory produces no finding", {
  result <- cl_check_installed_packages(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})
