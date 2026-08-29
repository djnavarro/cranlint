# Check for quoted function names in Title/Description

Flags a single-quoted word in the `Title` or `Description` field that
matches the name of a function defined in this package's own `R/` files,
or an exported function from `base`, `stats`, `utils`, or `methods`.
CRAN's single-quote convention is for software/package names, not
function names; quoting a function name is a common sign that the wrong
thing got quoted (e.g. `'summary'` where a software name was meant).

## Usage

``` r
cl_check_quoted_function_names(path = ".")
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
    Description = paste(
      "Provides a fast 'summary' method.",
      "It has no other dependencies."
    )
  )
)
cl_check_quoted_function_names(pkg_dir)
#> # A tibble: 1 × 6
#>   check                 file         line severity   message    policy_reference
#>   <chr>                 <chr>       <int> <ord>      <chr>      <chr>           
#> 1 quoted_function_names DESCRIPTION    NA should_fix 'summary'… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
