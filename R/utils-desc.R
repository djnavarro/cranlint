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
