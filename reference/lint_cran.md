# Run all cranlint checks against a package

Runs every `cl_check_*()` function against `path` and combines their
results into a single tibble. This is cranlint's single top-level entry
point, mirroring the role `lintr::lint()` plays for that package.

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

Checks run in this order:
[`cl_check_description_length()`](https://cranlint.djnavarro.net/reference/cl_check_description_length.md),
[`cl_check_title_case()`](https://cranlint.djnavarro.net/reference/cl_check_title_case.md),
[`cl_check_authors_r()`](https://cranlint.djnavarro.net/reference/cl_check_authors_r.md),
[`cl_check_hardcoded_seed()`](https://cranlint.djnavarro.net/reference/cl_check_hardcoded_seed.md),
[`cl_check_global_env_write()`](https://cranlint.djnavarro.net/reference/cl_check_global_env_write.md),
[`cl_check_installed_packages()`](https://cranlint.djnavarro.net/reference/cl_check_installed_packages.md),
[`cl_check_warn_suppression()`](https://cranlint.djnavarro.net/reference/cl_check_warn_suppression.md).
If a check errors – for example, because `path` has no `DESCRIPTION`
file at all – that error propagates rather than being caught and turned
into a result row, since it signals something more fundamental than an
individual finding. A single unparseable R file, by contrast, is already
handled gracefully by the underlying scan (skipped with a warning) and
does not stop the other checks from running.
