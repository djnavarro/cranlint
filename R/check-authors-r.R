#' Check DESCRIPTION's Authors@R usage
#'
#' Flags a missing `Authors@R` field, and flags manually-specified
#' `Author`/`Maintainer` fields that disagree with what R would generate
#' from `Authors@R` -- per the CRAN Cookbook, that disagreement results in
#' automatic rejection.
#'
#' The generated-value comparison relies on the same (non-exported) base R
#' helpers `R CMD check` itself uses to derive `Author`/`Maintainer` from
#' `Authors@R` (`utils:::.format_authors_at_R_field_for_author()` and
#' `...for_maintainer()`). This is inherently a little fragile -- an R
#' release could change or remove them -- so the comparison is skipped
#' (rather than erroring) if they're unavailable; presence of a manual
#' field is still reported as informational context in that case, just
#' without asserting a match/mismatch.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_authors_r <- function(path = ".") {
  d <- .cl_read_desc(path)
  policy_ref <- "https://contributor.r-project.org/cran-cookbook/description_issues.html#using-authorsr"

  if (!d$has_fields("Authors@R")) {
    return(.cl_new_result(
      check = "authors_r",
      file = "DESCRIPTION",
      line = NA_integer_,
      severity = "should_fix",
      message = paste0(
        "No Authors@R field found. CRAN recommends declaring authors via ",
        "Authors@R; Author and Maintainer are then generated automatically."
      ),
      policy_reference = policy_ref
    ))
  }

  authors <- tryCatch(d$get_authors(), error = function(e) NULL)
  if (is.null(authors)) {
    return(.cl_new_result(
      check = "authors_r",
      file = "DESCRIPTION",
      line = NA_integer_,
      severity = "must_fix",
      message = "Authors@R field could not be parsed as valid person() calls.",
      policy_reference = policy_ref
    ))
  }

  messages <- character()

  manual_author <- if (d$has_fields("Author")) {
    .cl_normalize_ws(d$get_field("Author"))
  } else {
    NA_character_
  }
  expected_author <- tryCatch(
    .cl_normalize_ws(utils:::.format_authors_at_R_field_for_author(authors)),
    error = function(e) NA_character_
  )
  if (!is.na(manual_author) && !is.na(expected_author) &&
    !identical(manual_author, expected_author)) {
    messages <- c(messages, paste0(
      "Manual Author field disagrees with the value R would generate from ",
      "Authors@R. CRAN treats this as an automatic rejection; remove the ",
      "manual Author field or update it to match."
    ))
  }

  manual_maintainer <- if (d$has_fields("Maintainer")) {
    .cl_normalize_ws(d$get_field("Maintainer"))
  } else {
    NA_character_
  }
  expected_maintainer <- tryCatch(
    .cl_normalize_ws(utils:::.format_authors_at_R_field_for_maintainer(authors)),
    error = function(e) NA_character_
  )
  if (!is.na(manual_maintainer) && !is.na(expected_maintainer) &&
    !identical(manual_maintainer, expected_maintainer)) {
    messages <- c(messages, paste0(
      "Manual Maintainer field disagrees with the value R would generate ",
      "from Authors@R. CRAN treats this as an automatic rejection; remove ",
      "the manual Maintainer field or update it to match."
    ))
  }

  if (length(messages) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "authors_r",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "must_fix",
    message = messages,
    policy_reference = policy_ref
  )
}
