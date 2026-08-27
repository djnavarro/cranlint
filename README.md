
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

What is special about using `README.Rmd` instead of just `README.md`?
You can include R chunks like so:

``` r
summary(cars)
#>      speed           dist       
#>  Min.   : 4.0   Min.   :  2.00  
#>  1st Qu.:12.0   1st Qu.: 26.00  
#>  Median :15.0   Median : 36.00  
#>  Mean   :15.4   Mean   : 42.98  
#>  3rd Qu.:19.0   3rd Qu.: 56.00  
#>  Max.   :25.0   Max.   :120.00
```

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date. `devtools::build_readme()` is handy for this.

You can also embed plots, for example:

<img src="man/figures/README-pressure-1.png" alt="" width="100%" />

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.
