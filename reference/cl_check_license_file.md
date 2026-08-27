# Check for unnecessary "+ file LICENSE" references

Flags a `License` field that references `+ file LICENSE` alongside a
base license that isn't one of the CRAN templates requiring an
additional file. Per the CRAN Cookbook, most licenses are bundled with R
itself and don't need a `LICENSE` file in the package; only `MIT`,
`BSD_2_clause`, and `BSD_3_clause` are templates that do (identifiable
via the `Note` column of
[`R.home()`](https://rdrr.io/r/base/Rhome.html)'s
`share/licenses/license.db`). A `LICENSE` file is otherwise only needed
when there are additional attribution requirements or restrictions
beyond the base license, which this check can't detect – so a finding
here is a prompt to review, not an automatic removal.

## Usage

``` r
cl_check_license_file(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.
