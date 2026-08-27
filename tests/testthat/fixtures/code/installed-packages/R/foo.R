has_pkg <- function(pkg) {
  pkg %in% rownames(installed.packages())
}

fine_check <- function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
}
