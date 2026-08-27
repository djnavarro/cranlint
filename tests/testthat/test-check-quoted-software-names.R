test_that("a quoted dependency name produces no finding", {
  result <- cl_check_quoted_software_names(test_path("fixtures/desc/quoted-good"))
  expect_equal(nrow(result), 0)
})

test_that("a package with no dependencies produces no finding", {
  result <- cl_check_quoted_software_names(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})

test_that("an unquoted dependency name is flagged", {
  result <- cl_check_quoted_software_names(test_path("fixtures/desc/quoted-unquoted-dep"))

  expect_equal(nrow(result), 1)
  expect_equal(result$check, "quoted_software_names")
  expect_equal(result$file, "DESCRIPTION")
  expect_true(is.na(result$line))
  expect_equal(as.character(result$severity), "advisory")
  expect_match(result$message, "\"ggplot2\" appears")
})
