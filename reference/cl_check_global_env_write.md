# Check for writes to enclosing/global environments via \<\<- or -\>\>

Flags `<<-`/`->>` usage in `R/`. This operator writes to the nearest
enclosing environment with an existing binding of the same name, or to
`.GlobalEnv` if none exists – which the CRAN Repository Policy
explicitly forbids. Package code that only uses `<<-` to update a
variable in a known parent scope (e.g. a closure factory) is technically
safe, but this check can't distinguish that case from an accidental
global write without deeper scope analysis, so every use is flagged for
review.

## Usage

``` r
cl_check_global_env_write(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.
