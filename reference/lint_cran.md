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

Every check other than
[`cl_check_missing_value()`](https://cranlint.djnavarro.net/reference/cl_check_missing_value.md)
only reads `path`.
[`cl_check_missing_value()`](https://cranlint.djnavarro.net/reference/cl_check_missing_value.md)
wraps
[`checkhelper::audit_tags()`](https://thinkr-open.github.io/checkhelper/reference/audit_tags.html),
which needs to actually load the package and re-run
[`roxygen2::roxygenise()`](https://roxygen2.r-lib.org/reference/roxygenize.html);
to keep `lint_cran()` itself side-effect-free on the caller's copy of
the package, that check runs against a disposable copy of `path` rather
than `path` directly (see
[`cl_check_missing_value()`](https://cranlint.djnavarro.net/reference/cl_check_missing_value.md)'s
documentation for details). It also relies on the `checkhelper` package
(Suggests); if that isn't installed, `lint_cran()` emits a warning and
skips just that check (contributing no rows) rather than erroring out
entirely, so `lint_cran()` stays usable without it. Calling
[`cl_check_missing_value()`](https://cranlint.djnavarro.net/reference/cl_check_missing_value.md)
directly still errors in that case.

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
#> Warning: roxygen2 requires Encoding: UTF-8
#> # A tibble: 2 × 6
#>   check              file          line severity   message      policy_reference
#>   <chr>              <chr>        <int> <ord>      <chr>        <chr>           
#> 1 description_length DESCRIPTION     NA should_fix The Descrip… https://contrib…
#> 2 hardcoded_seed     R/simulate.R     2 should_fix set.seed() … https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
