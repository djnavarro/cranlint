#' Run all cranlint checks against a package
#'
#' Runs every `cl_check_*()` check (DESCRIPTION issues like title case and
#' Authors@R formatting, and code/doc issues like hardcoded seeds and
#' `.GlobalEnv` writes) against `path` and combines their results into a
#' single tibble. This is cranlint's single top-level entry point,
#' mirroring the role `lintr::lint()` plays for that package.
#'
#' If a check errors -- for example, because `path` has no `DESCRIPTION`
#' file at all -- that error propagates rather than being caught and
#' turned into a result row, since it signals something more fundamental
#' than an individual finding. A single unparseable R file, by contrast,
#' is already handled gracefully (skipped with a warning) and does not
#' stop the other checks from running.
#'
#' Every check other than `cl_check_missing_value()` only reads `path`.
#' `cl_check_missing_value()` wraps `checkhelper::audit_tags()`, which
#' needs to actually load the package and re-run
#' `roxygen2::roxygenise()`; to keep `lint_cran()` itself side-effect-free
#' on the caller's copy of the package, that check runs against a
#' disposable copy of `path` rather than `path` directly (see
#' `cl_check_missing_value()`'s documentation for details). It also
#' relies on the `checkhelper` package (Suggests); if that isn't
#' installed, `lint_cran()` emits a warning and skips just that check
#' (contributing no rows) rather than erroring out entirely, so
#' `lint_cran()` stays usable without it. Calling
#' `cl_check_missing_value()` directly still errors in that case.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract (see
#'   `AGENTS.md`), combining every check's findings. Zero rows if no check
#'   reports any findings.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   description = c(Description = "Does a thing."),
#'   r_files = list(simulate.R = c(
#'     "simulate <- function() {",
#'     "  set.seed(42)",
#'     "  rnorm(1)",
#'     "}"
#'   ))
#' )
#' lint_cran(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
lint_cran <- function(path = ".") {
  checks <- list(
    cl_check_description_length,
    cl_check_title_case,
    cl_check_authors_r,
    cl_check_license_file,
    cl_check_doi_formatting,
    cl_check_quoted_software_names,
    cl_check_quoted_function_names,
    cl_check_hardcoded_seed,
    cl_check_global_env_write,
    cl_check_installed_packages,
    cl_check_warn_suppression,
    cl_check_verbose_output,
    cl_check_option_restoration,
    cl_check_dontrun_usage,
    cl_check_missing_value
  )

  results <- lapply(checks, function(check) {
    tryCatch(
      check(path),
      cranlint_missing_checkhelper = function(e) {
        warning(
          "Skipping cl_check_missing_value(): ", conditionMessage(e),
          call. = FALSE
        )
        .cl_new_result()
      }
    )
  })
  do.call(rbind, results)
}
