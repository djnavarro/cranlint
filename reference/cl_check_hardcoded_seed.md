# Check for hardcoded random seeds in package code

Flags [`set.seed()`](https://rdrr.io/r/base/Random.html) calls in `R/`
that pass a literal, unchangeable number (e.g. `set.seed(42)`,
`set.seed(seed = 42L)`, `set.seed(-5)`) as any argument. Setting a seed
a user can't override or opt out of, inside a function, is a common CRAN
rejection reason. Calls in `tests/`, `\examples`, `vignettes/`, and
demos are out of scope – and not scanned at all, since checks only look
at `R/` – because setting a seed there is expected and recommended for
reproducibility.

## Usage

``` r
cl_check_hardcoded_seed(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.
