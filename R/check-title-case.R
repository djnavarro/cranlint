#' Check that DESCRIPTION's Title field is in Title Case
#'
#' Compares the `Title` field against `tools::toTitleCase()`'s suggestion
#' and flags a mismatch. Title Case judgement genuinely depends on author
#' intent (proper nouns, quoted software names, etc. keep their original
#' casing), so treat a finding as a prompt to review rather than an
#' automatic rewrite.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   description = c(Title = "an example package")
#' )
#' cl_check_title_case(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_title_case <- function(path = ".") {
  d <- .cl_read_desc(path)
  title <- trimws(d$get_field("Title"))
  suggested <- tools::toTitleCase(title)

  if (identical(title, suggested)) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "title_case",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "should_fix",
    message = paste0(
      "Title does not match Title Case. Current: \"", title, "\". ",
      "tools::toTitleCase() suggests: \"", suggested, "\". Review before ",
      "changing -- toTitleCase() doesn't know about proper nouns or ",
      "software names that should keep their original casing."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/description_issues.html#title-case"
  )
}
