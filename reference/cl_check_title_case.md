# Check that DESCRIPTION's Title field is in Title Case

Compares the `Title` field against
[`tools::toTitleCase()`](https://rdrr.io/r/tools/toTitleCase.html)'s
suggestion and flags a mismatch. Title Case judgement genuinely depends
on author intent (proper nouns, quoted software names, etc. keep their
original casing), so treat a finding as a prompt to review rather than
an automatic rewrite.

## Usage

``` r
cl_check_title_case(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.
