# Check that DESCRIPTION's Description field is a full paragraph

Flags a `Description` field that reads as a single short sentence rather
than the short paragraph (2+ sentences) the CRAN Cookbook recommends.
Sentence counting is a heuristic (splitting on `.`/`!`/`?` followed by
whitespace or end-of-string) and can be thrown off by abbreviations;
treat findings as a prompt to review, not gospel.

## Usage

``` r
cl_check_description_length(path = ".")
```

## Arguments

- path:

  Path to the package root (the directory containing `DESCRIPTION`).
  Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.
