# Check DESCRIPTION's Authors@R usage

Flags a missing `Authors@R` field, and flags manually-specified
`Author`/`Maintainer` fields that disagree with what R would generate
from `Authors@R` – per the CRAN Cookbook, that disagreement results in
automatic rejection.

## Usage

``` r
cl_check_authors_r(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Details

The generated-value comparison reconstructs what `R CMD build` would
generate using only the exported
[`format()`](https://rdrr.io/r/base/format.html) generic for `person`
objects (see `.cl_expected_author()`/`.cl_expected_maintainer()` in
`R/utils-desc.R`), rather than calling the unexported base R helpers
that perform the equivalent comparison during `R CMD check` – doing so
via `:::` produced a dependency NOTE on every check, including in CI,
even though cranlint isn't meant for CRAN submission itself.
