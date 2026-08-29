# Check for print()/cat() calls outside print/format/summary methods

Flags a [`print()`](https://rdrr.io/r/base/print.html) or
[`cat()`](https://rdrr.io/r/base/cat.html) call in `R/` that isn't
nested inside a function whose name looks like a
`print.*`/`format.*`/`summary.*` S3 method. Per the CRAN Cookbook, these
produce console output a user can't suppress; CRAN's own exception is
printing inside `print`, `summary`, and similar methods, where it's the
whole point of the function.

## Usage

``` r
cl_check_verbose_output(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Details

Two things this check can't detect, so it will over-report relative to
what CRAN actually requires: a
[`cat()`](https://rdrr.io/r/base/cat.html) call writing to a
file/connection rather than the console (e.g.
`cat(x, file = "out.txt")`) is still flagged, and the Cookbook's other
accepted mitigation – gating the call behind a `verbose` argument, e.g.
`if (verbose) cat(...)` – isn't recognized as an exemption. Both are
worth a manual look before deciding a finding is a real problem.

## Examples

``` r
pkg_dir <- cl_example_pkg(
  r_files = list(foo.R = c(
    "process <- function(x) {",
    "  cat(\"processing...\\n\")",
    "  x",
    "}"
  ))
)
cl_check_verbose_output(pkg_dir)
#> # A tibble: 1 × 6
#>   check          file     line severity   message               policy_reference
#>   <chr>          <chr>   <int> <ord>      <chr>                 <chr>           
#> 1 verbose_output R/foo.R     2 should_fix cat() produces conso… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
