#' Read a package's DESCRIPTION file
#'
#' Thin wrapper around `desc::desc()` used by every DESCRIPTION-based check,
#' so the "package root" convention and error message stay consistent.
#'
#' @param path Path to the package root (the directory containing
#'   `DESCRIPTION`). Defaults to the current directory.
#' @return A `desc::description` R6 object.
#' @noRd
.cl_read_desc <- function(path = ".") {
  desc_path <- file.path(path, "DESCRIPTION")
  if (!file.exists(desc_path)) {
    stop("No DESCRIPTION file found at '", desc_path, "'.", call. = FALSE)
  }
  desc::desc(file = desc_path)
}

#' Collapse a field's internal whitespace (including DESCRIPTION's
#' line-wrapping) to single spaces, and trim leading/trailing whitespace.
#' @noRd
.cl_normalize_ws <- function(x) {
  gsub("\\s+", " ", trimws(x))
}

#' Escape a literal string for use inside a regular expression
#' @noRd
.cl_regex_escape <- function(x) {
  gsub("([.\\^$|()\\[\\]{}*+?])", "\\\\\\1", x, perl = TRUE)
}

#' Check whether a name appears in text without being wrapped in single quotes
#'
#' Used by `cl_check_quoted_software_names()`. Matches `name` as a whole
#' word (so e.g. `"table"` doesn't match inside `"data.table"`), and treats
#' an occurrence as already-quoted only when a literal `'` immediately
#' precedes and follows the match -- CRAN's convention of wrapping the
#' name directly in single quotes with no internal space.
#'
#' @param text The text to search (e.g. a package's Title + Description).
#' @param name The literal name to look for.
#' @return `TRUE` if `name` occurs at least once in `text` without being
#'   directly wrapped in single quotes, `FALSE` otherwise (including when
#'   `name` doesn't appear in `text` at all).
#' @noRd
.cl_has_unquoted_occurrence <- function(text, name) {
  pattern <- paste0("\\b", .cl_regex_escape(name), "\\b")
  m <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (identical(m[1], -1L)) {
    return(FALSE)
  }

  lens <- attr(m, "match.length")
  any(vapply(seq_along(m), function(i) {
    start <- m[i]
    end <- start + lens[i] - 1
    before <- substring(text, start - 1, start - 1)
    after <- substring(text, end + 1, end + 1)
    !(before == "'" && after == "'")
  }, logical(1)))
}

#' Extract single-quoted, identifier-like tokens from text
#'
#' Used by `cl_check_quoted_function_names()`. Matches a single word
#' (letters/digits/`.`/`_`/`:`, no spaces) wrapped in literal `'`, with an
#' optional trailing `()`, e.g. `'print'` or `'print()'`. Deliberately
#' narrow: a quoted multi-word phrase, or a quote pair split across an
#' English contraction elsewhere in the text (e.g. `"it's"` pairing with
#' an unrelated later `'`), won't match cleanly and is a known limitation
#' of matching on plain `'` rather than real markup.
#'
#' @param text The text to search (e.g. a package's Title + Description).
#' @return A character vector of the quoted tokens found (with any
#'   trailing `()` included), in order of appearance. Empty if none.
#' @noRd
.cl_quoted_tokens <- function(text) {
  regmatches(
    text,
    gregexpr("(?<=')[A-Za-z][\\w.:]*(\\(\\))?(?=')", text, perl = TRUE)
  )[[1]]
}

#' Reconstruct the Author field CRAN derives from Authors@R
#'
#' Mirrors the formatting `R CMD build` applies when generating the
#' `Author` field from `Authors@R`, using only the exported `format()`
#' generic for `person` objects (deliberately *not* the unexported base R
#' helpers `R CMD check` itself uses for the equivalent comparison --
#' calling those via `:::` produced a NOTE on every check, including in CI,
#' even though cranlint isn't meant for CRAN submission). Each person is
#' formatted as `"Given Family [roles]"` (no email), joined with `",\n  "`.
#'
#' @param persons A `person` object, as returned by `desc::get_authors()`.
#' @return A single character string, or `NA_character_` if formatting
#'   fails for any reason.
#' @noRd
.cl_expected_author <- function(persons) {
  tryCatch(
    .cl_normalize_ws(paste(
      format(persons, include = c("given", "family", "role")),
      collapse = ",\n  "
    )),
    error = function(e) NA_character_
  )
}

#' Reconstruct the Maintainer field CRAN derives from Authors@R
#'
#' Mirrors the formatting `R CMD build` applies when generating the
#' `Maintainer` field: the single person with role `"cre"`, formatted as
#' `"Given Family <email>"`. See `.cl_expected_author()` for why this
#' avoids the unexported base R helpers that do the equivalent derivation.
#'
#' @param persons A `person` object, as returned by `desc::get_authors()`.
#' @return A single character string, or `NA_character_` if there isn't
#'   exactly one person with role `"cre"` (an ambiguous or missing
#'   maintainer is a separate problem this helper doesn't try to diagnose)
#'   or formatting otherwise fails.
#' @noRd
.cl_expected_maintainer <- function(persons) {
  cre <- tryCatch(
    Filter(function(p) "cre" %in% p$role, persons),
    error = function(e) NULL
  )
  if (is.null(cre) || length(cre) != 1) {
    return(NA_character_)
  }
  tryCatch(
    .cl_normalize_ws(format(cre, include = c("given", "family", "email"))[1]),
    error = function(e) NA_character_
  )
}
