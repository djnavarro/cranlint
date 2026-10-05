#' Check for missing `\value`/`@return` documentation
#'
#' Flags exported functions and S3 methods whose generated `.Rd` file would
#' have no (or an empty) `\value` tag -- the cause of the CRAN Cookbook's
#' ["Missing `\\value` tags in .Rd
#' files"](https://contributor.r-project.org/cran-cookbook/docs_issues.html#missing-value-tags-in-.rd-files)
#' and the "Please add \\value to .Rd files" rejection message. This check
#' does not reimplement the detection logic itself (see `AGENTS.md`) --
#' it wraps `checkhelper::audit_tags()` and reshapes its output into the
#' standard cranlint check-result contract.
#'
#' `checkhelper::audit_tags()` works by actually loading the package's
#' namespace and re-running `roxygen2::roxygenise()` against it, which
#' writes `NAMESPACE`/`man/*.Rd` and may touch `DESCRIPTION`. To keep this
#' check read-only from the caller's point of view (matching every other
#' `cl_check_*()`), it runs against a disposable copy of `path` in a
#' temporary directory rather than `path` itself; nothing under `path` is
#' modified.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examplesIf requireNamespace("checkhelper", quietly = TRUE)
#' pkg_dir <- cl_example_pkg(
#'   description = c(Encoding = "UTF-8"),
#'   r_files = list(foo.R = c(
#'     "#' Foo",
#'     "#'",
#'     "#' @export",
#'     "foo <- function() 1"
#'   )),
#'   man_files = list()
#' )
#' dir.create(file.path(pkg_dir, "man"))
#' cl_check_missing_value(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_missing_value <- function(path = ".") {
  if (!requireNamespace("checkhelper", quietly = TRUE)) {
    stop(.cl_missing_checkhelper_cnd())
  }

  scratch <- .cl_copy_to_scratch(path)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)

  audit <- suppressMessages(checkhelper::audit_tags(scratch))
  fns <- audit$functions

  missing <- fns[fns$test_has_export_and_return == "not_ok", , drop = FALSE]

  if (nrow(missing) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "missing_value",
    file = file.path("man", paste0(missing$rdname_value, ".Rd")),
    line = NA_integer_,
    severity = "must_fix",
    message = paste0(
      "Exported function/method `", missing$topic, "` has no (or an ",
      "empty) \\value/@return tag. CRAN requires documenting the ",
      "structure and meaning of the return value -- or stating ",
      "explicitly that there is none, e.g. ",
      "\\value{No return value, called for side effects}."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/docs_issues.html#missing-value-tags-in-.rd-files"
  )
}

#' Build the condition signalled when `checkhelper` isn't installed
#'
#' A classed condition (rather than a plain `stop()` message) so
#' `lint_cran()` can specifically catch this one failure mode -- treating
#' a missing `Suggests` dependency as "skip this check" rather than
#' "abort the whole run" -- while still letting every other error from
#' `cl_check_missing_value()` (e.g. `checkhelper` itself failing to load
#' the package) propagate normally.
#'
#' @return A condition object with class `c("cranlint_missing_checkhelper",
#'   "error", "condition")`.
#' @noRd
.cl_missing_checkhelper_cnd <- function() {
  structure(
    class = c("cranlint_missing_checkhelper", "error", "condition"),
    list(
      message = paste0(
        "Package \"checkhelper\" is required for cl_check_missing_value(). ",
        "Install it with install.packages(\"checkhelper\")."
      ),
      call = NULL
    )
  )
}

#' Copy a package to a disposable temporary directory
#'
#' Used by checks that must hand a package off to a tool that mutates
#' files on disk (e.g. `checkhelper::audit_tags()`, which re-runs
#' `roxygen2::roxygenise()`), so that the caller's own copy of the
#' package is never touched.
#'
#' @param path Path to the package root.
#' @return Path to a new temporary directory containing a copy of `path`.
#' @noRd
.cl_copy_to_scratch <- function(path) {
  src <- normalizePath(path, mustWork = TRUE)
  scratch <- tempfile("cranlint_scratch_")
  dir.create(scratch)
  files <- list.files(src, all.files = TRUE, full.names = TRUE, no.. = TRUE)
  file.copy(files, scratch, recursive = TRUE)
  scratch
}
