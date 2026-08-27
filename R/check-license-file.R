#' Check for unnecessary "+ file LICENSE" references
#'
#' Flags a `License` field that references `+ file LICENSE` alongside a
#' base license that isn't one of the CRAN templates requiring an
#' additional file. Per the CRAN Cookbook, most licenses are bundled with R
#' itself and don't need a `LICENSE` file in the package; only `MIT`,
#' `BSD_2_clause`, and `BSD_3_clause` are templates that do (identifiable
#' via the `Note` column of `R.home()`'s `share/licenses/license.db`). A
#' `LICENSE` file is otherwise only needed when there are additional
#' attribution requirements or restrictions beyond the base license, which
#' this check can't detect -- so a finding here is a prompt to review, not
#' an automatic removal.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_license_file <- function(path = ".") {
  d <- .cl_read_desc(path)
  license <- trimws(d$get_field("License"))
  policy_ref <- "https://contributor.r-project.org/cran-cookbook/description_issues.html#license-files"

  file_suffix <- "\\s*\\+\\s*file\\s+LICENSE\\s*$"
  if (!grepl(file_suffix, license, ignore.case = TRUE)) {
    return(.cl_new_result())
  }

  base_license <- trimws(sub(file_suffix, "", license, ignore.case = TRUE))
  templated <- c("MIT", "BSD_2_clause", "BSD_3_clause")
  if (toupper(base_license) %in% toupper(templated)) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "license_file",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "should_fix",
    message = paste0(
      "License field is \"", license, "\". Only MIT, BSD_2_clause, and ",
      "BSD_3_clause are CRAN templates that require \"+ file LICENSE\"; ",
      "other licenses are bundled with R and don't need it. Remove ",
      "\"+ file LICENSE\" and the LICENSE file unless the package has ",
      "attribution requirements or other restrictions beyond the base ",
      "license."
    ),
    policy_reference = policy_ref
  )
}
