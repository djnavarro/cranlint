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

## Examples

``` r
pkg_dir <- cl_example_pkg(
  description = c(
    Description = paste(
      "See < doi:10.1000/xyz123> for background.",
      "It has no other dependencies."
    )
  )
)
cl_check_doi_formatting(pkg_dir)
#> # A tibble: 1 × 6
#>   check          file         line severity   message           policy_reference
#>   <chr>          <chr>       <int> <ord>      <chr>             <chr>           
#> 1 doi_formatting DESCRIPTION    NA should_fix "Reference \"< d… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
