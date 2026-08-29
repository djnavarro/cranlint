#' Check for `\dontrun{}` usage in .Rd examples
#'
#' Flags every line containing `\dontrun{` in a package's `man/*.Rd`
#' files. This is a soft, review-level finding rather than a hard fail:
#' `\dontrun{}` is a legitimate way to mark example code that genuinely
#' can't be run during checking (e.g. it needs credentials, a network
#' resource, or is illustrative pseudo-code), but it's also easy to
#' reach for out of habit for code that could run fine, or run via
#' `\donttest{}` instead (which CRAN does run, just not during every
#' regular check) -- and code inside `\dontrun{}` is never executed by
#' `R CMD check`, so it can silently rot. Static analysis can't tell
#' which case applies, so every occurrence is surfaced for a human to
#' judge.
#'
#' Matching is a plain line-based text search for the literal `\dontrun{`
#' markup within an `\examples{}` block, not a full Rd parse -- it doesn't
#' distinguish an active `\dontrun{}` from one that's commented out with
#' `%`, and reports one finding per line containing the markup rather than
#' per `\dontrun{}` block.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   man_files = list(foo.Rd = c(
#'     "\\name{foo}",
#'     "\\alias{foo}",
#'     "\\title{Foo}",
#'     "\\examples{",
#'     "\\dontrun{",
#'     "foo()",
#'     "}",
#'     "}"
#'   ))
#' )
#' cl_check_dontrun_usage(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_dontrun_usage <- function(path = ".") {
  man_files <- .cl_list_man_files(path)
  if (length(man_files) == 0) {
    return(.cl_new_result())
  }

  files <- character()
  lines <- integer()

  for (rel_file in names(man_files)) {
    file_lines <- tryCatch(
      readLines(man_files[[rel_file]], warn = FALSE),
      error = function(e) NULL
    )
    if (is.null(file_lines)) next

    examples_lines <- .cl_examples_lines(file_lines)
    if (length(examples_lines) == 0) next

    hits <- examples_lines[grepl("\\\\dontrun\\{", file_lines[examples_lines])]
    if (length(hits) == 0) next

    files <- c(files, rep(rel_file, length(hits)))
    lines <- c(lines, hits)
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "dontrun_usage",
    file = files,
    line = lines,
    severity = "advisory",
    message = paste0(
      "\\dontrun{} used in an example. Code inside \\dontrun{} is never ",
      "run by R CMD check, so it can silently rot; review whether it ",
      "could instead run unwrapped or via \\donttest{} (which CRAN does ",
      "run, just not during every regular check)."
    ),
    policy_reference = "https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Documenting-functions"
  )
}
