chatty <- function() {
  cat("hello")
  print("world")
}

quiet_helper <- function() {
  lapply(1:3, function(x) print(x))
}

print.myclass <- function(x, ...) {
  cat("printing", x, "\n")
  invisible(x)
}

format.myclass <- function(x, ...) {
  cat("formatting", x, "\n")
  as.character(x)
}

summary.myclass <- function(object, ...) {
  print("summary")
  invisible(object)
}

cat("top-level output")
