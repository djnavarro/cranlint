#' Check for writes to enclosing/global environments via <<- or ->>
#'
#' Flags `<<-`/`->>` usage in `R/`. This operator writes to the nearest
#' enclosing environment with an existing binding of the same name, or to
#' `.GlobalEnv` if none exists -- which the CRAN Repository Policy
#' explicitly forbids. Package code that only uses `<<-` to update a
#' variable in a known parent scope (e.g. a closure factory) is technically
#' safe, but this check can't distinguish that case from an accidental
#' global write without deeper scope analysis, so every use is flagged for
#' review.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @export
cl_check_global_env_write <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)

  files <- character()
  lines <- integer()
  operators <- character()

  for (rel_file in names(parsed_files)) {
    pd <- parsed_files[[rel_file]]
    hits <- pd[pd$text %in% c("<<-", "->>"), ]
    if (nrow(hits) == 0) next
    files <- c(files, rep(rel_file, nrow(hits)))
    lines <- c(lines, hits$line1)
    operators <- c(operators, hits$text)
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "global_env_write",
    file = files,
    line = lines,
    severity = "must_fix",
    message = paste0(
      "`", operators, "` used. This writes to the nearest enclosing scope ",
      "with an existing binding, or to .GlobalEnv otherwise -- modifying ",
      "the global environment is explicitly forbidden by CRAN policy."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/code_issues.html#writing-to-the-.globalenv"
  )
}
