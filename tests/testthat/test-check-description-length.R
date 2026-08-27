test_that("a multi-sentence Description produces no finding", {
  result <- cl_check_description_length(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("a single-sentence Description is flagged", {
  result <- cl_check_description_length(test_path("fixtures/desc/short-description"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "description_length")
  expect_equal(result$file, "DESCRIPTION")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "should_fix")
  expect_match(result$message, "single short sentence")
})
