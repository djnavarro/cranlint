#' Compute the net unescaped brace balance of a line
#'
#' Counts `{` as +1 and `}` as -1, skipping a brace immediately preceded
#' by `\\` (Rd's escape for a literal brace, which doesn't nest). Used by
#' `.cl_examples_lines()` to track brace depth while walking through an
#' `\examples{...}` block.
#'
#' @param line A single line of text.
#' @return A single integer: the net change in brace depth contributed
#'   by `line`.
#' @noRd
.cl_brace_delta <- function(line) {
  chars <- strsplit(line, "")[[1]]
  depth <- 0L
  i <- 1L
  n <- length(chars)
  while (i <= n) {
    ch <- chars[i]
    if (ch == "\\" && i < n && chars[i + 1] %in% c("{", "}")) {
      i <- i + 2L
      next
    }
    if (ch == "{") depth <- depth + 1L
    if (ch == "}") depth <- depth - 1L
    i <- i + 1L
  }
  depth
}

#' Find which lines of an .Rd file fall inside an \\examples{} block
#'
#' Walks the file tracking brace depth from each `\examples{` to its
#' matching closing `}` (handling multiple `\examples{}` blocks in one
#' file, and escaped braces via `.cl_brace_delta()`). Assumes `\examples{`
#' itself appears at the start of its own line, which holds for
#' roxygen2-generated and virtually all conventionally-formatted `.Rd`
#' files -- this is a line-based heuristic, not a full Rd parse.
#'
#' @param file_lines A character vector of an `.Rd` file's lines.
#' @return An integer vector of the 1-based line numbers that fall
#'   inside an `\examples{}` block (including the opening and closing
#'   lines themselves). Empty if the file has no `\examples{}` block.
#' @noRd
.cl_examples_lines <- function(file_lines) {
  in_examples <- FALSE
  depth <- 0L
  result <- integer()

  for (i in seq_along(file_lines)) {
    line <- file_lines[i]

    if (!in_examples) {
      if (grepl("\\\\examples\\{", line)) {
        in_examples <- TRUE
        depth <- .cl_brace_delta(line)
        result <- c(result, i)
        if (depth <= 0L) in_examples <- FALSE
      }
      next
    }

    depth <- depth + .cl_brace_delta(line)
    result <- c(result, i)
    if (depth <= 0L) in_examples <- FALSE
  }

  result
}

#' List .Rd files under a package's man/ directory
#'
#' Doc-level checks operate on the rendered `.Rd` files under `man/`
#' directly (rather than, say, roxygen comments in `R/`), since that's
#' what `R CMD check` actually processes regardless of whether the
#' package uses roxygen2 or hand-written Rd source.
#'
#' @param path Path to the package root. Defaults to the current directory.
#' @return A named character vector of file paths, named by their path
#'   relative to the package root (e.g. `"man/foo.Rd"`). Empty if there's
#'   no `man/` directory or it contains no `.Rd`/`.rd` files.
#' @noRd
.cl_list_man_files <- function(path = ".") {
  man_dir <- file.path(path, "man")
  if (!dir.exists(man_dir)) {
    return(character())
  }
  rel <- list.files(man_dir, pattern = "\\.[Rr]d$", recursive = TRUE)
  if (length(rel) == 0) {
    return(character())
  }
  stats::setNames(file.path(man_dir, rel), file.path("man", rel))
}
