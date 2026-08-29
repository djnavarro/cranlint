# Check for writes to enclosing/global environments via \<\<- or -\>\>

Flags `<<-`/`->>` usage in `R/`. This operator writes to the nearest
enclosing environment with an existing binding of the same name, or to
`.GlobalEnv` if none exists – which the CRAN Repository Policy
explicitly forbids. Package code that only uses `<<-` to update a
variable in a known parent scope (e.g. a closure factory) is technically
safe, but this check can't distinguish that case from an accidental
global write without deeper scope analysis, so every use is flagged for
review.

## Usage

``` r
cl_check_global_env_write(path = ".")
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
    "set_flag <- function() {",
    "  flag <<- TRUE",
    "}"
  ))
)
cl_check_global_env_write(pkg_dir)
#> # A tibble: 1 × 6
#>   check            file     line severity message               policy_reference
#>   <chr>            <chr>   <int> <ord>    <chr>                 <chr>           
#> 1 global_env_write R/foo.R     2 must_fix `<<-` used. This wri… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
