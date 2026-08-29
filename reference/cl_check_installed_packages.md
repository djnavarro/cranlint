# Check for calls to installed.packages()

Flags any call to
[`installed.packages()`](https://rdrr.io/r/utils/installed.packages.html)
in `R/`. Per the CRAN Cookbook, this function can be slow (it reads
several files per installed package) and shouldn't be used to test
whether a package is available;
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html)/[`require()`](https://rdrr.io/r/base/library.html)
are the recommended replacements (or
[`find.package()`](https://rdrr.io/r/base/find.package.html)/[`system.file()`](https://rdrr.io/r/base/system.file.html)
to locate one,
[`packageDescription()`](https://rdrr.io/r/utils/packageDescription.html)
for details of a small number of packages).

## Usage

``` r
cl_check_installed_packages(path = ".")
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
    "has_pkg <- function(pkg) {",
    "  pkg %in% rownames(installed.packages())",
    "}"
  ))
)
cl_check_installed_packages(pkg_dir)
#> # A tibble: 1 × 6
#>   check              file     line severity   message           policy_reference
#>   <chr>              <chr>   <int> <ord>      <chr>             <chr>           
#> 1 installed_packages R/foo.R     2 should_fix installed.packag… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
