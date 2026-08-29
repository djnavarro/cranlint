# Run all cranlint checks against a package

Runs every `cl_check_*()` check (DESCRIPTION issues like title case and
Authors@R formatting, and code/doc issues like hardcoded seeds and
`.GlobalEnv` writes) against `path` and combines their results into a
single tibble. This is cranlint's single top-level entry point,
mirroring the role `lintr::lint()` plays for that package.

## Usage

``` r
lint_cran(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract (see `AGENTS.md`),
combining every check's findings. Zero rows if no check reports any
findings.

## Details

If a check errors – for example, because `path` has no `DESCRIPTION`
file at all – that error propagates rather than being caught and turned
into a result row, since it signals something more fundamental than an
individual finding. A single unparseable R file, by contrast, is already
handled gracefully (skipped with a warning) and does not stop the other
checks from running.

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
