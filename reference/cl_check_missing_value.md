# Check for missing `\value`/`@return` documentation

Flags exported functions and S3 methods whose generated `.Rd` file would
have no (or an empty) `\value` tag – the cause of the CRAN Cookbook's
["Missing `\\value` tags in .Rd
files"](https://contributor.r-project.org/cran-cookbook/docs_issues.html#missing-value-tags-in-.rd-files)
and the "Please add \value to .Rd files" rejection message. This check
does not reimplement the detection logic itself (see `AGENTS.md`) – it
wraps
[`checkhelper::audit_tags()`](https://thinkr-open.github.io/checkhelper/reference/audit_tags.html)
and reshapes its output into the standard cranlint check-result
contract.

## Usage

``` r
cl_check_missing_value(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Details

[`checkhelper::audit_tags()`](https://thinkr-open.github.io/checkhelper/reference/audit_tags.html)
works by actually loading the package's namespace and re-running
[`roxygen2::roxygenise()`](https://roxygen2.r-lib.org/reference/roxygenize.html)
against it, which writes `NAMESPACE`/`man/*.Rd` and may touch
`DESCRIPTION`. To keep this check read-only from the caller's point of
view (matching every other `cl_check_*()`), it runs against a disposable
copy of `path` in a temporary directory rather than `path` itself;
nothing under `path` is modified.

## Examples

``` r
pkg_dir <- cl_example_pkg(
  description = c(Encoding = "UTF-8"),
  r_files = list(foo.R = c(
    "#' Foo",
    "#'",
    "#' @export",
    "foo <- function() 1"
  )),
  man_files = list()
)
dir.create(file.path(pkg_dir, "man"))
cl_check_missing_value(pkg_dir)
#> # A tibble: 1 × 6
#>   check         file        line severity message               policy_reference
#>   <chr>         <chr>      <int> <ord>    <chr>                 <chr>           
#> 1 missing_value man/foo.Rd    NA must_fix "Exported function/m… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
