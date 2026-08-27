test_that("a well-formatted doi reference produces no finding", {
  result <- cl_check_doi_formatting(test_path("fixtures/desc/doi-good"))
  expect_equal(nrow(result), 0)
})

test_that("a Description with no reference produces no finding", {
  result <- cl_check_doi_formatting(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("a space after the doi: prefix is flagged", {
  result <- cl_check_doi_formatting(test_path("fixtures/desc/doi-bad-space-after-colon"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "doi_formatting")
  expect_equal(result$file, "DESCRIPTION")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "should_fix")
  expect_match(result$message, "<doi: 10.18637")
})

test_that("a space after the opening angle bracket is flagged", {
  result <- cl_check_doi_formatting(test_path("fixtures/desc/doi-bad-space-after-bracket"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "doi_formatting")
  expect_match(result$message, "< doi:10.18637")
})
