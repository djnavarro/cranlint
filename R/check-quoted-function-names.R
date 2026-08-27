#' Check for quoted function names in Title/Description
#'
#' Flags a single-quoted word in the `Title` or `Description` field that
#' matches the name of a function defined in this package's own `R/` files,
#' or an exported function from `base`, `stats`, `utils`, or `methods`.
#' CRAN's single-quote convention is for software/package names, not
#' function names; quoting a function name is a common sign that the wrong
#' thing got quoted (e.g. `'summary'` where a software name was meant).
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_quoted_function_names <- function(path = ".") {
  d <- .cl_read_desc(path)
  policy_ref <- "https://contributor.r-project.org/cran-cookbook/description_issues.html#formatting-software-names"

  text <- paste(
    trimws(d$get_field("Title")),
    .cl_normalize_ws(d$get_field("Description"))
  )

  quoted <- unique(.cl_quoted_tokens(text))
  if (length(quoted) == 0) {
    return(.cl_new_result())
  }

  own_fns <- .cl_defined_function_names(path)
  base_fns <- .cl_base_function_names()

  messages <- character()
  for (token in quoted) {
    bare <- sub("\\(\\)$", "", token)
    if (bare %in% own_fns) {
      messages <- c(messages, paste0(
        "'", token, "' is quoted in Title/Description, but it matches a ",
        "function defined in this package's own R/ files. Single quotes ",
        "are for software/package names, not function names -- check ",
        "whether the wrong thing got quoted."
      ))
    } else if (bare %in% base_fns) {
      messages <- c(messages, paste0(
        "'", token, "' is quoted in Title/Description, but it matches a ",
        "base R function (", bare, "()). Single quotes are for software/",
        "package names, not function names -- check whether the wrong ",
        "thing got quoted."
      ))
    }
  }

  if (length(messages) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "quoted_function_names",
    file = "DESCRIPTION",
    line = NA_integer_,
    severity = "should_fix",
    message = messages,
    policy_reference = policy_ref
  )
}
