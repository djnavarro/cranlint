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
