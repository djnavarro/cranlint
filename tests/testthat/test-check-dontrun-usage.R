test_that("a package with no man/ directory produces no finding", {
  result <- cl_check_dontrun_usage(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("man/ files with no \\dontrun{} produce no finding", {
  result <- cl_check_dontrun_usage(test_path("fixtures/man/clean"))
  expect_equal(nrow(result), 0)
})

test_that("\\dontrun{} usage is flagged once per occurrence, across files", {
  result <- cl_check_dontrun_usage(test_path("fixtures/man/dontrun"))

  expect_equal(nrow(result), 2)
  expect_true(all(result$check == "dontrun_usage"))
  expect_true(all(as.character(result$severity) == "advisory"))
  expect_setequal(result$file, c("man/foo.Rd", "man/bar.Rd"))
  expect_match(result$message, "\\\\dontrun\\{\\} used in an example")
})

test_that("the flagged line matches where \\dontrun{ appears", {
  result <- cl_check_dontrun_usage(test_path("fixtures/man/dontrun"))

  foo_row <- result[result$file == "man/foo.Rd", ]
  bar_row <- result[result$file == "man/bar.Rd", ]
  expect_equal(foo_row$line, 15L)
  expect_equal(bar_row$line, 14L)
})
