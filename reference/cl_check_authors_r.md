# Check DESCRIPTION's Authors@R usage

Flags a missing `Authors@R` field, and flags manually-specified
`Author`/`Maintainer` fields that disagree with what R would generate
from `Authors@R` – per the CRAN Cookbook, that disagreement results in
automatic rejection.

## Usage

``` r
cl_check_authors_r(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Examples

``` r
pkg_dir <- cl_example_pkg(
  description = c(
    Author = "Someone Else",
    Maintainer = "Someone Else <someone@example.com>"
  )
)
cl_check_authors_r(pkg_dir)
#> # A tibble: 2 × 6
#>   check     file         line severity message                  policy_reference
#>   <chr>     <chr>       <int> <ord>    <chr>                    <chr>           
#> 1 authors_r DESCRIPTION    NA must_fix Manual Author field dis… https://contrib…
#> 2 authors_r DESCRIPTION    NA must_fix Manual Maintainer field… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
