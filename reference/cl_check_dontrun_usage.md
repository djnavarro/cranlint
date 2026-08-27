# Check for `\dontrun{}` usage in .Rd examples

Flags every line containing `\dontrun{` in a package's `man/*.Rd` files.
This is a soft, review-level finding rather than a hard fail:
`\dontrun{}` is a legitimate way to mark example code that genuinely
can't be run during checking (e.g. it needs credentials, a network
resource, or is illustrative pseudo-code), but it's also easy to reach
for out of habit for code that could run fine, or run via `\donttest{}`
instead (which CRAN does run, just not during every regular check) – and
code inside `\dontrun{}` is never executed by `R CMD check`, so it can
silently rot. Static analysis can't tell which case applies, so every
occurrence is surfaced for a human to judge.

## Usage

``` r
cl_check_dontrun_usage(path = ".")
```

## Arguments

- path:

  Path to the package root. Defaults to the current directory.

## Value

A tibble following the cranlint check-result contract; see `AGENTS.md`.

## Details

Matching is a plain line-based text search for the literal `\dontrun{`
markup within an `\examples{}` block, not a full Rd parse – it doesn't
distinguish an active `\dontrun{}` from one that's commented out with
`%`, and reports one finding per line containing the markup rather than
per `\dontrun{}` block. The search is deliberately scoped to
`\examples{}` (see `.cl_examples_lines()`) so that prose elsewhere in
the page that merely *mentions* `\dontrun{}` – e.g. a `@details` tag
discussing the markup, as this very function's own documentation does –
isn't mistaken for actual usage.
