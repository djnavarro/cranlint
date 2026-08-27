# Check that the package's own dependencies are quoted in Title/Description

Flags a package name from this package's own `Depends`/`Imports`/
`Suggests`/`LinkingTo` fields (excluding `"R"` itself) that appears
unquoted in the `Title` or `Description` field. Per the CRAN Cookbook,
software and package names should be wrapped in single quotes so the
automatic spell check doesn't flag them.

## Usage

``` r
cl_check_quoted_software_names(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Details

The candidate list is deliberately narrow: rather than a general list of
known software/API names (high false-positive risk – see
`.agents/PLAN.md`), it's limited to packages this package actually
declares a dependency on, which keeps precision high. It also means the
check under-reports (e.g. it won't catch an unquoted "Python"). A plain
word matching a dependency's name doesn't always refer to the package
either, so findings are advisory rather than a firm "fix this."
