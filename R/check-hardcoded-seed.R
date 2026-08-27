#' Check for hardcoded random seeds in package code
#'
#' Flags `set.seed()` calls in `R/` that pass a literal, unchangeable
#' number (e.g. `set.seed(42)`, `set.seed(seed = 42L)`, `set.seed(-5)`) as
#' any argument. Setting a seed a user can't override or opt out of, inside
#' a function, is a common CRAN rejection reason. Calls in `tests/`,
#' `\examples`, `vignettes/`, and demos are out of scope -- and not scanned
#' at all, since checks only look at `R/` -- because setting a seed there
#' is expected and recommended for reproducibility.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_hardcoded_seed <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)

  files <- character()
  lines <- integer()

  for (rel_file in names(parsed_files)) {
    pd <- parsed_files[[rel_file]]
    calls <- .cl_find_calls(pd, "set.seed")
    if (nrow(calls) == 0) next

    for (i in seq_len(nrow(calls))) {
      args <- .cl_call_arg_texts(pd, calls[i, ])
      if (any(grepl("^-?[0-9]+\\.?[0-9]*[Li]?$", args))) {
        files <- c(files, rel_file)
        lines <- c(lines, calls$line1[i])
      }
    }
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "hardcoded_seed",
    file = files,
    line = lines,
    severity = "should_fix",
    message = paste0(
      "set.seed() called with a literal, unchangeable seed value. Users ",
      "should be able to control (or opt out of) the seed, e.g. via a ",
      "`seed = NULL` function argument."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/code_issues.html#setting-a-specific-seed"
  )
}
