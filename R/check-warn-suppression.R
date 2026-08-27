#' Check for options(warn = <negative>)
#'
#' Flags `options()` calls that set `warn` to a negative value, which
#' globally suppresses all warnings for the rest of the session and can't
#' be limited to a specific expression. Per the CRAN Cookbook, this is not
#' allowed even when the option is immediately restored afterwards;
#' `suppressWarnings()` around the specific expression is the recommended
#' replacement.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_warn_suppression <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)

  files <- character()
  lines <- integer()

  for (rel_file in names(parsed_files)) {
    pd <- parsed_files[[rel_file]]
    calls <- .cl_find_calls(pd, "options")
    if (nrow(calls) == 0) next

    for (i in seq_len(nrow(calls))) {
      args <- .cl_call_args(pd, calls[i, ])
      warn_args <- args[args$name == "warn", , drop = FALSE]
      if (any(grepl("^-[0-9]+\\.?[0-9]*$", warn_args$text))) {
        files <- c(files, rel_file)
        lines <- c(lines, calls$line1[i])
      }
    }
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "warn_suppression",
    file = files,
    line = lines,
    severity = "must_fix",
    message = paste0(
      "options(warn = <negative>) globally suppresses all warnings. CRAN ",
      "does not allow this, even if restored afterwards; use ",
      "suppressWarnings() around the specific expression instead."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/code_issues.html#setting-optionswarn--1"
  )
}
