bad_par <- function() {
  par(mfrow = c(2, 2))
  plot(1)
}

good_par <- function() {
  old <- par(no.readonly = TRUE)
  on.exit(par(old))
  par(mfrow = c(2, 2))
}

bad_options <- function() {
  options(warn = 1)
}

good_options <- function() {
  old <- options(warn = 1)
  on.exit(options(old))
}

query_par <- function() {
  par("mfrow")
}

bad_setwd <- function() {
  setwd(tempdir())
}

nested_bad <- function() {
  helper <- function() {
    on.exit(par(list()))
  }
  par(mfrow = c(1, 1))
  helper()
}
