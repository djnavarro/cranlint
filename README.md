
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cranlint

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/cranlint/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/cranlint/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of cranlint is to catch common, easy-to-miss mistakes made when
preparing an R package for CRAN submission – things like hardcoded
random seeds, DESCRIPTION formatting issues, and writes to `.GlobalEnv`
– that complement (rather than duplicate) tools like
[checkhelper](https://thinkr-open.github.io/checkhelper/),
[lintr](https://lintr.r-lib.org/), and
[spelling](https://docs.ropensci.org/spelling/).

## Installation

You can install the development version of cranlint from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("djnavarro/cranlint")
```

## Example

`lint_cran()` runs every cranlint check against a package and returns a
single tibble of findings. Here it’s pointed at a tiny example package
with two easy-to-miss issues: a one-sentence `Description` field, and a
hardcoded `set.seed()` call inside a function.

``` r
library(cranlint)

pkg_dir <- tempfile("examplepkg")
dir.create(file.path(pkg_dir, "R"), recursive = TRUE)

writeLines(
  c(
    "Package: examplepkg",
    "Title: An Example Package",
    "Version: 0.0.1",
    "Authors@R: person(\"Jane\", \"Doe\", email = \"jane@example.com\", role = c(\"aut\", \"cre\"))",
    "Description: Does a thing.",
    "License: MIT + file LICENSE"
  ),
  file.path(pkg_dir, "DESCRIPTION")
)

writeLines(
  c(
    "simulate <- function() {",
    "  set.seed(42)",
    "  rnorm(1)",
    "}"
  ),
  file.path(pkg_dir, "R", "simulate.R")
)

lint_cran(pkg_dir)
#> # A tibble: 2 × 6
#>   check              file          line severity   message      policy_reference
#>   <chr>              <chr>        <int> <ord>      <chr>        <chr>           
#> 1 description_length DESCRIPTION     NA should_fix The Descrip… https://contrib…
#> 2 hardcoded_seed     R/simulate.R     2 should_fix set.seed() … https://contrib…
```
