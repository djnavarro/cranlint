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

#' Get each argument of a call as a name/value pair
#'
#' @param pd The parse-data data frame the call row came from.
#' @param call_row A single row of `pd`, as returned by `.cl_find_calls()`.
#' @return A data frame with one row per argument, in argument order, and
#'   columns `name` (the argument name, or `""` for a positional argument)
#'   and `text` (the source text of the argument's value expression). Zero
#'   rows if the call has no arguments or its structure can't be resolved.
#' @noRd
.cl_call_args <- function(pd, call_row) {
  callee_expr_id <- call_row$parent
  call_expr_id <- pd$parent[pd$id == callee_expr_id]
  if (length(call_expr_id) == 0) {
    return(data.frame(name = character(), text = character(), stringsAsFactors = FALSE))
  }

  # Named arguments show up as a SYMBOL_SUB token (the name) followed by an
  # EQ_SUB token ('='), then the value's own `expr` node -- all as siblings
  # under the call's expr id. Walk siblings in source order, remembering the
  # most recent SYMBOL_SUB as the pending name for the next `expr` we see.
  children <- pd[pd$parent == call_expr_id & pd$id != callee_expr_id, ]
  children <- children[order(children$line1, children$col1), ]

  names <- character()
  texts <- character()
  pending_name <- NA_character_
  for (i in seq_len(nrow(children))) {
    row <- children[i, ]
    if (row$token == "SYMBOL_SUB") {
      pending_name <- trimws(row$text)
    } else if (row$token == "expr") {
      names <- c(names, if (is.na(pending_name)) "" else pending_name)
      texts <- c(texts, trimws(row$text))
      pending_name <- NA_character_
    }
  }

  data.frame(name = names, text = texts, stringsAsFactors = FALSE)
}

#' Find function-valued top-level and nested assignments in parse data
#'
#' Walks every `<-`/`=` assignment in `pd` (at any nesting level -- a
#' helper defined inside another function still counts) and records the
#' assigned name and the `id` of the `function(...)` expr when the
#' right-hand side is a function definition. The `id` is what lets
#' `.cl_enclosing_function_names()` map a function-definition expr found
#' while walking up a call's ancestor chain back to the name it was
#' assigned to (if any -- anonymous functions have no matching row here).
#'
#' @param pd A parse-data data frame from `.cl_scan_r_files()`.
#' @return A data frame with one row per named function assignment found,
#'   and columns `id` (the function `expr`'s parse-data id) and `name`
#'   (the assigned name). Zero rows if none are found.
#' @noRd
.cl_function_assignments <- function(pd) {
  assigns <- pd[pd$token %in% c("LEFT_ASSIGN", "EQ_ASSIGN"), ]
  ids <- integer()
  names_out <- character()
  for (i in seq_len(nrow(assigns))) {
    a <- assigns[i, ]
    siblings <- pd[pd$parent == a$parent, ]
    siblings <- siblings[order(siblings$line1, siblings$col1), ]
    pos <- which(siblings$id == a$id)
    if (length(pos) != 1 || pos <= 1 || pos >= nrow(siblings)) next

    lhs_child <- siblings[pos - 1, ]
    rhs_child <- siblings[pos + 1, ]
    sym <- pd[pd$parent == lhs_child$id & pd$token == "SYMBOL", ]
    if (nrow(sym) != 1) next

    if (any(pd$parent == rhs_child$id & pd$token == "FUNCTION")) {
      ids <- c(ids, rhs_child$id)
      names_out <- c(names_out, sym$text)
    }
  }
  data.frame(id = ids, name = names_out, stringsAsFactors = FALSE)
}

#' Find function-valued top-level and nested assignments in parse data
#'
#' Thin wrapper around `.cl_function_assignments()` for callers that only
#' need the names, not the `id`s. Used by `cl_check_quoted_function_names()`
#' to build the list of function names "owned" by the package being linted.
#'
#' @param pd A parse-data data frame from `.cl_scan_r_files()`.
#' @return A character vector of function names, possibly with
#'   duplicates removed but otherwise unprocessed (no deduplication across
#'   multiple files -- callers combine and dedupe themselves).
#' @noRd
.cl_extract_function_names <- function(pd) {
  .cl_function_assignments(pd)$name
}

#' List every function name defined anywhere in a package's R/ directory
#'
#' @param path Path to the package root. Defaults to the current directory.
#' @return A unique character vector of function names. Empty if there's
#'   no `R/` directory or it defines no functions.
#' @noRd
.cl_defined_function_names <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)
  unique(unlist(lapply(parsed_files, .cl_extract_function_names), use.names = FALSE))
}

#' Find the names of every named function enclosing a given parse-data row
#'
#' Walks up `row`'s ancestor chain (via `parent` ids) to the top of the
#' file, collecting the assigned name of every function definition passed
#' through along the way -- not just the innermost one, so a call nested
#' inside an anonymous helper (e.g. inside `lapply(x, function(z) ...)`)
#' still surfaces the name of whatever named function encloses that
#' helper. Anonymous functions in the chain contribute nothing (they have
#' no row in `.cl_function_assignments()`) but don't stop the walk.
#'
#' @param pd A parse-data data frame from `.cl_scan_r_files()`.
#' @param row A single row of `pd` (e.g. a call site from
#'   `.cl_find_calls()`) to find the enclosing function names of.
#' @return A character vector of enclosing function names, innermost
#'   first. Empty if `row` isn't nested inside any named function (e.g.
#'   it's a top-level call, or only nested inside anonymous functions).
#' @noRd
.cl_enclosing_function_names <- function(pd, row) {
  assignments <- .cl_function_assignments(pd)
  fn_names <- stats::setNames(assignments$name, as.character(assignments$id))

  found <- character()
  current <- row$parent
  seen <- integer()
  while (length(current) == 1 && !is.na(current) && current != 0) {
    if (current %in% seen) break
    seen <- c(seen, current)

    if (any(pd$parent == current & pd$token == "FUNCTION")) {
      nm <- unname(fn_names[as.character(current)])
      if (!is.na(nm)) found <- c(found, nm)
    }

    parent_row <- pd$parent[pd$id == current]
    current <- if (length(parent_row) == 0) NA_integer_ else parent_row[1]
  }
  found
}

#' List exported function names from R's always-attached base packages
#'
#' Covers `base`, `stats`, `utils`, and `methods` -- the packages every R
#' installation ships and (by default) attaches, regardless of what the
#' linted package depends on. Used by `cl_check_quoted_function_names()`
#' to catch a quoted reference to a common base R function (e.g.
#' `'print'`). Looked up via the namespace directly (`getNamespaceExports()`)
#' rather than the search path, so the result doesn't depend on whether
#' these packages happen to be attached in the calling session.
#'
#' @return A unique character vector of function names.
#' @noRd
.cl_base_function_names <- function() {
  pkgs <- c("base", "stats", "utils", "methods")
  fn_names <- character()
  for (pkg in pkgs) {
    ns <- asNamespace(pkg)
    exported <- getNamespaceExports(pkg)
    is_fn <- vapply(exported, function(nm) {
      exists(nm, envir = ns, inherits = FALSE) &&
        is.function(get(nm, envir = ns, inherits = FALSE))
    }, logical(1))
    fn_names <- c(fn_names, exported[is_fn])
  }
  unique(fn_names)
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
  .cl_call_args(pd, call_row)$text
}
