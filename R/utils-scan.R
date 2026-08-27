#' List R source files under a package's R/ directory
#'
#' Code-level checks operate on `R/` only, not `tests/`, `vignettes/`, or
#' man page examples -- exactly the places where things like a hardcoded
#' `set.seed()` are expected and recommended rather than a mistake.
#'
#' @param path Path to the package root. Defaults to the current directory.
#' @return A named character vector of file paths, named by their path
#'   relative to the package root (e.g. `"R/foo.R"`). Empty if there's no
#'   `R/` directory or it contains no `.R` files.
#' @noRd
.cl_list_r_files <- function(path = ".") {
  r_dir <- file.path(path, "R")
  if (!dir.exists(r_dir)) {
    return(character())
  }
  rel <- list.files(r_dir, pattern = "\\.[Rr]$", recursive = TRUE)
  if (length(rel) == 0) {
    return(character())
  }
  stats::setNames(file.path(r_dir, rel), file.path("R", rel))
}

#' Parse a single R file into token-level parse data
#'
#' @param file Path to the file to parse.
#' @param rel_file Path relative to the package root, used for the warning
#'   message and stored in the returned `file` column.
#' @return A data frame from `utils::getParseData()`, with an added `file`
#'   column, or `NULL` (with a warning) if the file has a syntax error.
#' @noRd
.cl_parse_r_file <- function(file, rel_file) {
  expr <- tryCatch(parse(file, keep.source = TRUE), error = function(e) NULL)
  if (is.null(expr)) {
    warning(
      "cranlint could not parse '", rel_file, "'; skipping it.",
      call. = FALSE
    )
    return(NULL)
  }
  pd <- utils::getParseData(expr, includeText = TRUE)
  pd$file <- rel_file
  pd
}

#' Parse every R file in a package's R/ directory
#'
#' The shared entry point for code-level checks. Files that fail to parse
#' are skipped (with a warning) rather than aborting the whole scan, so one
#' broken file doesn't prevent findings in the rest of the package.
#'
#' @param path Path to the package root. Defaults to the current directory.
#' @return A named list of parse-data data frames (see
#'   `utils::getParseData()`), one per file, named by the file's path
#'   relative to the package root. Empty list if there's no `R/` directory,
#'   it has no `.R` files, or none of them parse successfully.
#' @noRd
.cl_scan_r_files <- function(path = ".") {
  files <- .cl_list_r_files(path)
  if (length(files) == 0) {
    return(list())
  }
  parsed <- Map(.cl_parse_r_file, files, names(files))
  Filter(Negate(is.null), parsed)
}

#' Find calls to a given function in a file's parse data
#'
#' @param pd A parse-data data frame from `.cl_scan_r_files()`.
#' @param fun_names Character vector of function names to look for (matched
#'   against the bare, unqualified call; `pkg::fun()` call sites are not
#'   currently detected).
#' @return The subset of `pd` where each row is one `SYMBOL_FUNCTION_CALL`
#'   token matching `fun_names`.
#' @noRd
.cl_find_calls <- function(pd, fun_names) {
  pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% fun_names, ]
}

#' Get the source text of each argument expression in a call
#'
#' @param pd The parse-data data frame the call row came from.
#' @param call_row A single row of `pd`, as returned by `.cl_find_calls()`.
#' @return A character vector of the source text of each argument
#'   expression (positional or named; for named arguments this is only the
#'   value, not the `name =` part), in argument order. Empty if the call
#'   has no arguments or its structure can't be resolved.
#' @noRd
.cl_call_arg_texts <- function(pd, call_row) {
  callee_expr_id <- call_row$parent
  call_expr_id <- pd$parent[pd$id == callee_expr_id]
  if (length(call_expr_id) == 0) {
    return(character())
  }
  arg_rows <- pd[
    pd$parent == call_expr_id & pd$token == "expr" & pd$id != callee_expr_id,
  ]
  trimws(arg_rows$text)
}
