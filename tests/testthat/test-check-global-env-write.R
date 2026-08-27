test_that("code with no <<- or ->> produces no finding", {
  result <- cl_check_global_env_write(test_path("fixtures/code/clean"))
  expect_equal(nrow(result), 0)
})

test_that("<<- and ->> are flagged; plain <- is not", {
  result <- cl_check_global_env_write(test_path("fixtures/code/global-env-write"))

  expect_equal(nrow(result), 2)
  expect_true(all(result$check == "global_env_write"))
  expect_true(all(result$file == "R/foo.R"))
  expect_true(all(as.character(result$severity) == "must_fix"))
  expect_setequal(result$line, c(4L, 10L))
  expect_match(result$message[result$line == 4L], "<<-", fixed = TRUE)
  expect_match(result$message[result$line == 10L], "->>", fixed = TRUE)
})

test_that("a package with no R/ directory produces no finding", {
  result <- cl_check_global_env_write(test_path("fixtures/desc/good"))
  expect_equal(nrow(result), 0)
})
