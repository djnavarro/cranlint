#' Check that DESCRIPTION's Description field is a full paragraph
#'
#' Flags a `Description` field that reads as a single short sentence
#' rather than the short paragraph (2+ sentences) the CRAN Cookbook
#' recommends. Sentence counting is a heuristic (splitting on `.`/`!`/`?`
#' followed by whitespace or end-of-string) and can be thrown off by
#' abbreviations; treat findings as a prompt to review, not gospel.
#'
#' @param path Path to the package root (the directory containing
#'   `DESCRIPTION`). Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   description = c(Description = "Does a thing.")
#' )
#' cl_check_description_length(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_description_length <- function(path = ".") {
  d <- .cl_read_desc(path)
  flat <- .cl_normalize_ws(d$get_field("Description"))

  sentence_ends <- gregexpr("[.!?](?=\\s|$)", flat, perl = TRUE)[[1]]
  sentence_count <- if (identical(sentence_ends[1], -1L)) 0L else length(sentence_ends)

  if (sentence_count >= 2) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "description_length",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "should_fix",
    message = paste0(
      "The Description field reads as a single short sentence. CRAN's ",
      "guidance is for this field to be a short paragraph (2+ sentences) ",
      "describing the package's purpose and motivation."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/general_issues.html#description-length"
  )
}
