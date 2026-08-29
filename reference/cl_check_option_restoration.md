# Check for unrestored par()/options()/setwd() changes

Flags a [`par()`](https://rdrr.io/r/graphics/par.html),
[`options()`](https://rdrr.io/r/base/options.html), or
[`setwd()`](https://rdrr.io/r/base/getwd.html) call in `R/` that changes
state without a paired
[`on.exit()`](https://rdrr.io/r/base/on.exit.html) call in the same
function frame to restore it. Per the CRAN Cookbook, packages shouldn't
permanently change a user's graphical parameters, options, or working
directory; if a function has to, it should save the old value and
restore it with [`on.exit()`](https://rdrr.io/r/base/on.exit.html)
immediately.

## Usage

``` r
cl_check_option_restoration(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Details

[`setwd()`](https://rdrr.io/r/base/getwd.html) always counts as a
change. For
[`par()`](https://rdrr.io/r/graphics/par.html)/[`options()`](https://rdrr.io/r/base/options.html),
a bare call with no arguments, or a call whose only arguments are
unnamed (e.g. `par("mfrow")`, or `par(oldpar)`/`options(oldopts)`
restoring a previously-saved list) is treated as a query/restore rather
than a change and isn't flagged; `par(no.readonly = TRUE)` is also
excluded as it's the standard snapshot-for-later-restore idiom, not a
change by itself.

This is a coarse heuristic: it doesn't check that the
[`on.exit()`](https://rdrr.io/r/base/on.exit.html) call actually
restores the *same* thing that was changed, or that the restore happens
immediately after the change – only that both are present in the same
function frame. A change with no enclosing function at all is always
flagged, since [`on.exit()`](https://rdrr.io/r/base/on.exit.html)
couldn't apply there anyway.

## Examples

``` r
pkg_dir <- cl_example_pkg(
  r_files = list(foo.R = c(
    "plot_thing <- function() {",
    "  par(mfrow = c(1, 2))",
    "  plot(1)",
    "}"
  ))
)
cl_check_option_restoration(pkg_dir)
#> # A tibble: 1 × 6
#>   check              file     line severity   message           policy_reference
#>   <chr>              <chr>   <int> <ord>      <chr>             <chr>           
#> 1 option_restoration R/foo.R     2 should_fix par() changes st… https://contrib…
unlink(pkg_dir, recursive = TRUE)
```
