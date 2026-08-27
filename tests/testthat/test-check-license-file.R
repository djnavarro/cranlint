test_that("MIT + file LICENSE produces no finding", {
  result <- cl_check_license_file(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("License with no + file LICENSE suffix produces no finding", {
  result <- cl_check_license_file(test_path("fixtures/desc/license-no-file"))
  expect_equal(nrow(result), 0)
})

test_that("+ file LICENSE on a non-templated license is flagged", {
  result <- cl_check_license_file(test_path("fixtures/desc/license-unneeded-file"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "license_file")
  expect_equal(result$file, "DESCRIPTION")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "should_fix")
  expect_match(result$message, "GPL-3 \\+ file LICENSE")
})
