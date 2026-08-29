#' Check for unrestored par()/options()/setwd() changes
#'
#' Flags a `par()`, `options()`, or `setwd()` call in `R/` that changes
#' state without a paired `on.exit()` call in the same function frame to
#' restore it. Per the CRAN Cookbook, packages shouldn't permanently
#' change a user's graphical parameters, options, or working directory;
#' if a function has to, it should save the old value and restore it with
#' `on.exit()` immediately.
#'
#' `setwd()` always counts as a change. For `par()`/`options()`, a bare
#' call with no arguments, or a call whose only arguments are unnamed
#' (e.g. `par("mfrow")`, or `par(oldpar)`/`options(oldopts)` restoring a
#' previously-saved list) is treated as a query/restore rather than a
#' change and isn't flagged; `par(no.readonly = TRUE)` is also excluded
#' as it's the standard snapshot-for-later-restore idiom, not a change by
#' itself.
#'
#' This is a coarse heuristic: it doesn't check that the `on.exit()` call
#' actually restores the *same* thing that was changed, or that the
#' restore happens immediately after the change -- only that both are
#' present in the same function frame. A change with no enclosing function
#' at all is always flagged, since `on.exit()` couldn't apply there anyway.
#'
#' @param path Path to the package root. Defaults to the current directory.
#'
#' @return A tibble following the cranlint check-result contract; see
#'   `AGENTS.md`.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   r_files = list(foo.R = c(
#'     "plot_thing <- function() {",
#'     "  par(mfrow = c(1, 2))",
#'     "  plot(1)",
#'     "}"
#'   ))
#' )
#' cl_check_option_restoration(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_check_option_restoration <- function(path = ".") {
  parsed_files <- .cl_scan_r_files(path)

  files <- character()
  lines <- integer()
  fn_texts <- character()

  for (rel_file in names(parsed_files)) {
    pd <- parsed_files[[rel_file]]
    onexit_fn_ids <- .cl_onexit_frame_ids(pd)

    for (fn_name in c("par", "options", "setwd")) {
      calls <- .cl_find_calls(pd, fn_name)
      if (nrow(calls) == 0) next

      for (i in seq_len(nrow(calls))) {
        call_row <- calls[i, ]
        args <- .cl_call_args(pd, call_row)
        if (!.cl_is_state_change(fn_name, args)) next

        fn_id <- .cl_innermost_enclosing_function_id(pd, call_row)
        if (!is.na(fn_id) && fn_id %in% onexit_fn_ids) next

        files <- c(files, rel_file)
        lines <- c(lines, call_row$line1)
        fn_texts <- c(fn_texts, call_row$text)
      }
    }
  }

  if (length(files) == 0) {
    return(.cl_new_result())
  }

  .cl_new_result(
    check = "option_restoration",
    file = files,
    line = lines,
    severity = "should_fix",
    message = paste0(
      fn_texts, "() changes state without a paired on.exit() restore in ",
      "the same function. Save the old value and restore it immediately, ",
      "e.g. `old <- ", fn_texts, "(...); on.exit(", fn_texts, "(old))`."
    ),
    policy_reference = "https://contributor.r-project.org/cran-cookbook/code_issues.html#change-of-options-graphical-parameters-and-working-directory"
  )
}

#' Which function frames contain an `on.exit()` call
#'
#' @param pd A parse-data data frame from `.cl_scan_r_files()`.
#' @return An integer vector of function-definition `expr` ids (as
#'   returned by `.cl_innermost_enclosing_function_id()`) that directly
#'   contain at least one `on.exit()` call.
#' @noRd
.cl_onexit_frame_ids <- function(pd) {
  onexit_calls <- .cl_find_calls(pd, "on.exit")
  if (nrow(onexit_calls) == 0) {
    return(integer())
  }

  ids <- vapply(seq_len(nrow(onexit_calls)), function(i) {
    .cl_innermost_enclosing_function_id(pd, onexit_calls[i, ])
  }, integer(1))
  unique(ids[!is.na(ids)])
}

#' Decide whether a par()/options()/setwd() call changes state
#'
#' @param fn_name The function name (`"par"`, `"options"`, or `"setwd"`).
#' @param args The call's arguments, as returned by `.cl_call_args()`.
#' @return `TRUE` if the call should be treated as a state change
#'   requiring a paired `on.exit()` restore, `FALSE` for a query/restore
#'   call. See `cl_check_option_restoration()`'s documentation for the
#'   specific rules.
#' @noRd
.cl_is_state_change <- function(fn_name, args) {
  if (fn_name == "setwd") {
    return(TRUE)
  }
  if (nrow(args) == 0) {
    return(FALSE)
  }
  if (fn_name == "par" && nrow(args) == 1 && identical(args$name[1], "no.readonly")) {
    return(FALSE)
  }
  any(args$name != "")
}
