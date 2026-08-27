simulate <- function() {
  set.seed(42)
  rnorm(1)
}

simulate_named <- function() {
  set.seed(seed = 123)
  rnorm(1)
}

simulate_negative <- function() {
  set.seed(-5)
  rnorm(1)
}

simulate_integer_literal <- function() {
  set.seed(42L)
  rnorm(1)
}

simulate_dynamic <- function(seed) {
  set.seed(seed)
  rnorm(1)
}
