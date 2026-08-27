#' Severity levels for cranlint check results, in increasing order of
#' urgency. See the output contract in `AGENTS.md`.
#' @noRd
.cl_severity_levels <- c("advisory", "should_fix", "must_fix")

#' Construct a cranlint check-result tibble
#'
#' Every `cl_check_*()` function builds its return value with this helper,
#' so the shape (column names/types) stays consistent across checks. Calling
#' it with no arguments returns a well-typed, zero-row tibble -- the
#' contract a check should follow when it finds no issues.
#'
#' @param check Character. Short id of the check, e.g. `"hardcoded_seed"`.
#' @param file Character. Path to the affected file, relative to the
#'   package root, e.g. `"R/foo.R"` or `"DESCRIPTION"`.
#' @param line Integer. Line number of the finding, or `NA_integer_` when a
#'   finding isn't tied to a specific line.
#' @param severity Character, one of `.cl_severity_levels`.
#' @param message Character. Human-readable description of the finding.
#' @param policy_reference Character. URL/citation to the CRAN policy or
#'   Cookbook recipe motivating the check.
#'
#' @return A tibble with columns `check`, `file`, `line`, `severity` (an
#'   ordered factor), `message`, and `policy_reference`. Zero rows if all
#'   arguments are empty. Scalar arguments are recycled to the length of the
#'   longest argument, following normal `tibble::tibble()` recycling rules.
#' @noRd
.cl_new_result <- function(check = character(),
                            file = character(),
                            line = integer(),
                            severity = character(),
                            message = character(),
                            policy_reference = character()) {
  severity <- as.character(severity)
  bad <- setdiff(unique(severity), .cl_severity_levels)
  if (length(bad) > 0) {
    stop(
      "Invalid `severity` value(s): ", paste(bad, collapse = ", "), ".\n",
      "Must be one of: ", paste(.cl_severity_levels, collapse = ", "), ".",
      call. = FALSE
    )
  }

  tibble::tibble(
    check = as.character(check),
    file = as.character(file),
    line = as.integer(line),
    severity = factor(severity, levels = .cl_severity_levels, ordered = TRUE),
    message = as.character(message),
    policy_reference = as.character(policy_reference)
  )
}
