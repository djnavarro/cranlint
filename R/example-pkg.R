#' Scaffold a minimal package on disk for trying out cranlint checks
#'
#' Writes a valid, minimal package (a `DESCRIPTION` file, and optionally
#' `R/` and `man/` files) to a new temporary directory. This exists to
#' support the runnable `@examples` on `cl_check_*()`/`lint_cran()`, and
#' to make it easy to try cranlint out interactively, without needing a
#' real package on disk -- it is not part of the actual linting logic.
#'
#' @param description A named character vector of DESCRIPTION fields to
#'   add or override on top of a minimal default (`Package`, `Title`,
#'   `Version`, `Authors@R`, `Description`, `License`).
#' @param r_files A named list mapping a filename (e.g. `"foo.R"`) to a
#'   character vector of lines, written under `R/`.
#' @param man_files A named list mapping a filename (e.g. `"foo.Rd"`) to
#'   a character vector of lines, written under `man/`.
#'
#' @return The path to the scaffolded package (a tempdir). Callers should
#'   `unlink(path, recursive = TRUE)` once done with it.
#' @examples
#' pkg_dir <- cl_example_pkg(
#'   description = c(Description = "Does a thing."),
#'   r_files = list(simulate.R = c(
#'     "simulate <- function() {",
#'     "  set.seed(42)",
#'     "  rnorm(1)",
#'     "}"
#'   ))
#' )
#' lint_cran(pkg_dir)
#' unlink(pkg_dir, recursive = TRUE)
#' @export
cl_example_pkg <- function(description = character(),
                            r_files = list(),
                            man_files = list()) {
  fields <- utils::modifyList(
    list(
      Package = "examplepkg",
      Title = "An Example Package",
      Version = "0.0.1",
      "Authors@R" = "person(\"Jane\", \"Doe\", email = \"jane@example.com\", role = c(\"aut\", \"cre\"))",
      Description = "Does a thing. It does the thing reliably.",
      License = "MIT + file LICENSE"
    ),
    as.list(description)
  )

  pkg_dir <- tempfile("examplepkg")
  dir.create(pkg_dir, recursive = TRUE)
  writeLines(
    paste0(names(fields), ": ", vapply(fields, as.character, character(1))),
    file.path(pkg_dir, "DESCRIPTION")
  )

  if (length(r_files) > 0) {
    dir.create(file.path(pkg_dir, "R"), showWarnings = FALSE)
    for (fname in names(r_files)) {
      writeLines(r_files[[fname]], file.path(pkg_dir, "R", fname))
    }
  }

  if (length(man_files) > 0) {
    dir.create(file.path(pkg_dir, "man"), showWarnings = FALSE)
    for (fname in names(man_files)) {
      writeLines(man_files[[fname]], file.path(pkg_dir, "man", fname))
    }
  }

  pkg_dir
}
