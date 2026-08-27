test_that("a clean DESCRIPTION-only fixture with no R/ produces no findings", {
  result <- lint_cran(test_path("fixtures/desc/good"))

  expect_s3_class(result, "tbl_df")
  expect_equal(
    names(result),
    c("check", "file", "line", "severity", "message", "policy_reference")
  )
  expect_equal(nrow(result), 0)
})

test_that("findings from multiple checks are combined into one tibble", {
  # This fixture has no DESCRIPTION problems, but its R/ file has both a
  # hardcoded seed and a <<- write, so lint_cran() should surface findings
  # from more than one check at once.
  result <- lint_cran(test_path("fixtures/lint-cran/mixed-issues"))

  expect_true(all(c("hardcoded_seed", "global_env_write") %in% result$check))
  expect_equal(nrow(result), 2)
})

test_that("a missing DESCRIPTION propagates an error rather than an empty result", {
  expect_error(lint_cran(local_tempdir()))
})
