# Check DOI/URL reference formatting in the Description field

Flags `<doi:...>`/`<https:...>` references in the `Description` field
that have whitespace right after the opening angle bracket or right
after the `doi:`/`https:` prefix, which breaks CRAN's auto-linking of
the reference. This is a text-matching heuristic on `<...>` spans that
look like a reference; it can't verify the reference is otherwise
well-formed (e.g. a real DOI).

## Usage

``` r
cl_check_doi_formatting(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.
