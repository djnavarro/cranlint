quiet_call <- function() {
  options(warn = -1)
  1
}

quiet_call_multi <- function() {
  options(digits = 3, warn = -2)
  1
}

fine_call <- function() {
  options(warn = 1)
  suppressWarnings(sqrt(-1))
}
