simulate <- function() {
  set.seed(42)
  rnorm(1)
}

make_counter <- function() {
  count <- 0
  function() {
    count <<- count + 1
    count
  }
}
