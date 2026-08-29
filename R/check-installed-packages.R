#' Check for calls to installed.packages()
#'
#' Flags any call to `installed.packages()` in `R/`. Per the CRAN Cookbook,
#' this function can be slow (it reads several files per installed
#' package) and shouldn't be used to test whether a package is available;
#' `requireNamespace()`/`require()` are the recommended replacements (or
#' `find.package()`/`system.file()` to locate one, `packageDescription()`
#' for details of a small number of packages).
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   r_files = list(foo.R = c(
#'     "has_pkg <- function(pkg) {",
#'     "  pkg %in% rownames(installed.packages())",
#'     "}"
#'   ))
#' )
#' cl_check_installed_packages(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_installed_packages <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)

  files <- character()
  lines <- integer()

  for (rel_file in names(parsed_files)) {
    pd <- parsed_files[[rel_file]]
    calls <- .cl_find_calls(pd, "installed.packages")
    if (nrow(calls) == 0) next
    files <- c(files, rep(rel_file, nrow(calls)))
    lines <- c(lines, calls$line1)
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "installed_packages",
    file = files,
    line = lines,
    severity = "should_fix",
    message = paste0(
      "installed.packages() called. This can be slow and shouldn't be ",
      "used to test package availability; use requireNamespace()/",
      "require() instead (or find.package()/system.file() to locate a ",
      "package, packageDescription() for details of a few packages)."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/code_issues.html#calling-installed.packages"
  )
}
