#' Check for print()/cat() calls outside print/format/summary methods
#'
#' Flags a `print()` or `cat()` call in `R/` that isn't nested inside a
#' function whose name looks like a `print.*`/`format.*`/`summary.*` S3
#' method. Per the CRAN Cookbook, these produce console output a user
#' can't suppress; CRAN's own exception is printing inside `print`,
#' `summary`, and similar methods, where it's the whole point of the
#' function.
#'
#' The enclosing-function lookup walks the full ancestor chain, not just
#' the innermost function, so a call nested inside an anonymous helper
#' (e.g. inside `lapply(x, function(z) ...)`) is still correctly
#' attributed to whatever named function encloses that helper.
#'
#' Two things this check can't detect, so it will over-report relative to
#' what CRAN actually requires: a `cat()` call writing to a file/connection
#' rather than the console (e.g. `cat(x, file = "out.txt")`) is still
#' flagged, and the Cookbook's other accepted mitigation -- gating the
#' call behind a `verbose` argument, e.g. `if (verbose) cat(...)` -- isn't
#' recognized as an exemption. Both are worth a manual look before
#' deciding a finding is a real problem.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_verbose_output <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)
  s3_exempt <- "^(print|format|summary)\\."

  files <- character()
  lines <- integer()
  messages <- character()

  for (rel_file in names(parsed_files)) {
    pd <- parsed_files[[rel_file]]
    calls <- .cl_find_calls(pd, c("print", "cat"))
    if (nrow(calls) == 0) next

    for (i in seq_len(nrow(calls))) {
      call_row <- calls[i, ]
      enclosing <- .cl_enclosing_function_names(pd, call_row)
      if (any(grepl(s3_exempt, enclosing))) next

      files <- c(files, rel_file)
      lines <- c(lines, call_row$line1)
      messages <- c(messages, paste0(
        call_row$text, "() produces console output that users can't ",
        "suppress. Use message()/warning() instead, or gate the call ",
        "behind a verbose argument (if (verbose) ", call_row$text, "(...)). ",
        "Exempt if this is inside a print/format/summary S3 method."
      ))
    }
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "verbose_output",
    file = files,
    line = lines,
    severity = "should_fix",
    message = messages,
    policy_reference = "https://contributor.r-project.org/cran-cookbook/code_issues.html#using-printcat"
  )
}
