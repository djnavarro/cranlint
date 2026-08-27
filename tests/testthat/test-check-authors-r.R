test_that("Authors@R with no manual Author/Maintainer produces no finding", {
  result <- cl_check_authors_r(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("missing Authors@R is flagged", {
  result <- cl_check_authors_r(test_path("fixtures/desc/no-authors-r"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "authors_r")
  expect_equal(as.character(result$severity), "should_fix")
  expect_match(result$message, "No Authors@R field found")
})

test_that("Authors@R present with matching manual fields produces no finding", {
  result <- cl_check_authors_r(test_path("fixtures/desc/authors-r-consistent"))
  expect_equal(nrow(result), 0)
})

test_that("Authors@R present with mismatched manual fields is flagged for both", {
  result <- cl_check_authors_r(test_path("fixtures/desc/authors-r-mismatch"))

  expect_equal(nrow(result), 2)
  expect_true(all(result$check == "authors_r"))
  expect_true(all(as.character(result$severity) == "must_fix"))
  expect_match(result$message[1], "Manual Author field disagrees")
  expect_match(result$message[2], "Manual Maintainer field disagrees")
})
