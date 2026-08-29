# Check for options(warn = )

Flags [`options()`](https://rdrr.io/r/base/options.html) calls that set
`warn` to a negative value, which globally suppresses all warnings for
the rest of the session and can't be limited to a specific expression.
Per the CRAN Cookbook, this is not allowed even when the option is
immediately restored afterwards;
[`suppressWarnings()`](https://rdrr.io/r/base/warning.html) around the
specific expression is the recommended replacement.

## Usage

``` r
cl_check_warn_suppression(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Examples

``` r
pkg_dir <- cl_example_pkg(
  r_files = list(foo.R = c(
    "quietly <- function() {",
    "  options(warn = -1)",
    "}"
  ))
)
cl_check_warn_suppression(pkg_dir)
#> # A tibble: 1 × 6
#>   check            file     line severity message               policy_reference
#>   <chr>            <chr>   <int> <ord>    <chr>                 <chr>           
#> 1 warn_suppression R/foo.R     2 must_fix options(warn = <nega… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
