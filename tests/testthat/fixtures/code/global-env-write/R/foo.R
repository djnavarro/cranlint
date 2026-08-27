make_counter <- function() {
  count <- 0
  function() {
    count <<- count + 1
    count
  }
}

bad_write <- function() {
  1 ->> leaked
}

fine_assignment <- function() {
  x <- 1
  x
}
