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
