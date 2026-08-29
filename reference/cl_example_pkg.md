# Scaffold a minimal package on disk for trying out cranlint checks

Writes a valid, minimal package (a `DESCRIPTION` file, and optionally
`R/` and `man/` files) to a new temporary directory. This exists to
support the runnable `@examples` on
`cl_check_*()`/[`lint_cran()`](https://cranlint.djnavarro.net/reference/lint_cran.md),
and to make it easy to try cranlint out interactively, without needing a
real package on disk – it is not part of the actual linting logic.

## Usage

``` r
cl_example_pkg(description = character(), r_files = list(), man_files = list())
```

## Arguments

- description:

  A named character vector of DESCRIPTION fields to add or override on
  top of a minimal default (`Package`, `Title`, `Version`, `Authors@R`,
  `Description`, `License`).

- r_files:

  A named list mapping a filename (e.g. `"foo.R"`) to a character vector
  of lines, written under `R/`.

- man_files:

  A named list mapping a filename (e.g. `"foo.Rd"`) to a character
  vector of lines, written under `man/`.

## Value

The path to the scaffolded package (a tempdir). Callers should
`unlink(path, recursive = TRUE)` once done with it.

## Examples

``` r
pkg_dir <- cl_example_pkg(
  description = c(Description = "Does a thing."),
  r_files = list(simulate.R = c(
    "simulate <- function() {",
    "  set.seed(42)",
    "  rnorm(1)",
    "}"
  ))
)
lint_cran(pkg_dir)
#> # A tibble: 2 × 6
#>   check              file          line severity   message      policy_reference
#>   <chr>              <chr>        <int> <ord>      <chr>        <chr>           
#> 1 description_length DESCRIPTION     NA should_fix The Descrip… https://contrib…
#> 2 hardcoded_seed     R/simulate.R     2 should_fix set.seed() … https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
