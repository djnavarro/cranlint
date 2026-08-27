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

The generated-value comparison relies on the same (non-exported) base R
helpers `R CMD check` itself uses to derive `Author`/`Maintainer` from
`Authors@R` (`utils:::.format_authors_at_R_field_for_author()` and
`...for_maintainer()`). This is inherently a little fragile – an R
release could change or remove them – so the comparison is skipped
(rather than erroring) if they're unavailable; presence of a manual
field is still reported as informational context in that case, just
without asserting a match/mismatch.
