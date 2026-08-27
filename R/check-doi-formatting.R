#' Check DOI/URL reference formatting in the Description field
#'
#' Flags `<doi:...>`/`<https:...>` references in the `Description` field
#' that have whitespace right after the opening angle bracket or right
#' after the `doi:`/`https:` prefix, which breaks CRAN's auto-linking of
#' the reference. This is a text-matching heuristic on `<...>` spans that
#' look like a reference; it can't verify the reference is otherwise
#' well-formed (e.g. a real DOI).
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_doi_formatting <- function(path = ".") {
  d <- .cl_read_desc(path)
  flat <- .cl_normalize_ws(d$get_field("Description"))
  policy_ref <- "https://contributor.r-project.org/cran-cookbook/description_issues.html#references"

  brackets <- regmatches(flat, gregexpr("<[^<>]*>", flat))[[1]]
  ref_like <- brackets[grepl("^<\\s*(doi|https?)\\s*:", brackets, ignore.case = TRUE)]
  bad <- ref_like[grepl("^<\\s+", ref_like) | grepl(":\\s+", ref_like)]

  if (length(bad) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "doi_formatting",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "should_fix",
    message = paste0(
      "Reference \"", bad, "\" in Description has whitespace right after ",
      "the opening angle bracket or the doi:/https: prefix, which breaks ",
      "CRAN's auto-linking. Remove the space, e.g. <doi:10.xxxx/yyy>."
    ),
    policy_reference = policy_ref
  )
}
