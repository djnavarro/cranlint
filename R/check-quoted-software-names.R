#' Check that the package's own dependencies are quoted in Title/Description
#'
#' Flags a package name from this package's own `Depends`/`Imports`/
#' `Suggests`/`LinkingTo` fields (excluding `"R"` itself) that appears
#' unquoted in the `Title` or `Description` field. Per the CRAN Cookbook,
#' software and package names should be wrapped in single quotes so the
#' automatic spell check doesn't flag them.
#'
#' The candidate list is deliberately narrow: rather than a general list
#' of known software/API names (high false-positive risk -- see
#' `.agents/PLAN.md`), it's limited to packages this package actually
#' declares a dependency on, which keeps precision high. It also means the
#' check under-reports (e.g. it won't catch an unquoted "Python"). A plain
#' word matching a dependency's name doesn't always refer to the package
#' either, so findings are advisory rather than a firm "fix this."
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   description = c(
#'     Description = paste(
#'       "Wraps jsonlite for convenient parsing.",
#'       "It has no other dependencies."
#'     ),
#'     Imports = "jsonlite"
#'   )
#' )
#' cl_check_quoted_software_names(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_quoted_software_names <- function(path = ".") {
  d <- .cl_read_desc(path)
  policy_ref <- "https://contributor.r-project.org/cran-cookbook/description_issues.html#formatting-software-names"

  candidates <- unique(setdiff(d$get_deps()$package, "R"))
  if (length(candidates) == 0) {
    return(.cl_new_result())
  }

  text <- paste(
    trimws(d$get_field("Title")),
    .cl_normalize_ws(d$get_field("Description"))
  )

  flagged <- Filter(function(name) .cl_has_unquoted_occurrence(text, name), candidates)
  if (length(flagged) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "quoted_software_names",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "advisory",
    message = paste0(
      "\"", flagged, "\" appears in Title/Description without single ",
      "quotes. If this refers to the '", flagged, "' package, CRAN asks ",
      "that software/package names be wrapped in single quotes, e.g. ",
      "'", flagged, "'."
    ),
    policy_reference = policy_ref
  )
}
