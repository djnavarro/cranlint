test_that(".cl_list_r_files finds .R files under R/, named with R/ prefix", {
  root <- test_path("fixtures/code/clean")
  files <- .cl_list_r_files(root)

  expect_equal(unname(files), file.path(root, "R", "foo.R"))
  expect_equal(names(files), "R/foo.R")
})

test_that(".cl_list_r_files returns character(0) when there's no R/ directory", {
  expect_equal(.cl_list_r_files(test_path("fixtures/desc/good")), character())
})

test_that(".cl_scan_r_files returns one parse-data frame per file", {
  parsed <- .cl_scan_r_files(test_path("fixtures/code/clean"))
  expect_equal(names(parsed), "R/foo.R")
  expect_s3_class(parsed[["R/foo.R"]], "data.frame")
})

test_that(".cl_scan_r_files skips unparseable files with a warning", {
  expect_warning(
    parsed <- .cl_scan_r_files(test_path("fixtures/code/parse-error")),
    "could not parse"
  )
  expect_equal(names(parsed), "R/good.R")
})

test_that(".cl_find_calls and .cl_call_arg_texts extract call arguments", {
  pd <- utils::getParseData(
    parse(text = "set.seed(42)\nset.seed(x)\nset.seed(seed = 7)\n", keep.source = TRUE),
    includeText = TRUE
  )
  calls <- .cl_find_calls(pd, "set.seed")
  expect_equal(nrow(calls), 3)

  args <- lapply(seq_len(nrow(calls)), function(i) .cl_call_arg_texts(pd, calls[i, ]))
  expect_equal(unlist(args), c("42", "x", "7"))
})

test_that(".cl_find_calls returns zero rows when the function isn't called", {
  pd <- utils::getParseData(
    parse(text = "1 + 1\n", keep.source = TRUE),
    includeText = TRUE
  )
  expect_equal(nrow(.cl_find_calls(pd, "set.seed")), 0)
})

test_that(".cl_call_args pairs argument names with their value text", {
  pd <- utils::getParseData(
    parse(
      text = "options(warn = -1)\noptions(digits = 3, warn = -2)\n",
      keep.source = TRUE
    ),
    includeText = TRUE
  )
  calls <- .cl_find_calls(pd, "options")

  args1 <- .cl_call_args(pd, calls[1, ])
  expect_equal(args1$name, "warn")
  expect_equal(args1$text, "-1")

  args2 <- .cl_call_args(pd, calls[2, ])
  expect_equal(args2$name, c("digits", "warn"))
  expect_equal(args2$text, c("3", "-2"))
})

test_that(".cl_call_args gives positional arguments an empty name", {
  pd <- utils::getParseData(
    parse(text = "set.seed(42)\n", keep.source = TRUE),
    includeText = TRUE
  )
  calls <- .cl_find_calls(pd, "set.seed")
  args <- .cl_call_args(pd, calls[1, ])

  expect_equal(args$name, "")
  expect_equal(args$text, "42")
})
