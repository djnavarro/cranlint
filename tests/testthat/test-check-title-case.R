test_that("a Title Case Title produces no finding", {
  result <- cl_check_title_case(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("a non-title-case Title is flagged", {
  result <- cl_check_title_case(test_path("fixtures/desc/bad-title"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "title_case")
  expect_equal(result$file, "DESCRIPTION")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "should_fix")
  expect_match(result$message, "does not match Title Case")
  expect_match(result$message, "Tools for Doing Good Things")
})
