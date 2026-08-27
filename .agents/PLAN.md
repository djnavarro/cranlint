# cranlint development plan

This document tracks scoped-out future development for cranlint -- work
that's been thought about but not done, or deliberately deferred. It is not
a changelog: once an item here is completed, its write-up should move to
[.agents/HISTORY.md](HISTORY.md) and be removed from this file rather than
marked "done" in place.

Last reviewed: 2026-08-28 (v1 check inventory now complete).

## v1 check inventory

Drafted from the [CRAN Cookbook](https://contributor.r-project.org/cran-cookbook/)
(all four chapters), cross-checked against `checkhelper`, `lintr`, and
`spelling`/`urlchecker` to avoid duplicating existing coverage. Proposed
build order (cheapest/highest-value first):

### DESCRIPTION checks

1. `check_description_length()` -- Description field is a single short
   sentence rather than a real paragraph.
2. `check_title_case()` -- Title field not in title case (compare against
   `tools::toTitleCase()`).
3. `check_authors_r()` -- missing `Authors@R`, or manual `Author`/
   `Maintainer` fields inconsistent with it (parse via `desc`).
All checks from the v1 inventory have been implemented; see
`.agents/HISTORY.md` for design write-ups.

### Explicitly out of scope for `cranlint` (static analysis can't do these)

- **Overall checktime > 10 min** and **temp-directory detritus** -- both
  require actually running examples/tests/checks, not static analysis.
  These belong to `checkhelper::check_as_cran()` / `rcmdcheck`, not here.
- **Acronym explanation** in DESCRIPTION -- unautomatable, semantic
  judgement call.
- **Missing `\value`/`@return` tags** -- already covered by
  `checkhelper::find_missing_tags()`; wrap rather than reimplement.
- **`T`/`F` instead of `TRUE`/`FALSE`** -- already covered by
  `lintr::T_and_F_symbol_linter()`; wrap rather than reimplement.

### Lower-priority / maybe

- `check_stale_rd()` -- `man/*.Rd` not regenerated after `R/*.R` roxygen
  comments changed (compare mtimes, or diff a fresh `roxygen2::roxygenize()`
  dry run). Medium difficulty.
- Reminder-only check for missing `cran-comments.md`. Low value on its own;
  consider bundling into the orchestrator's summary output rather than a
  standalone check.
- `check_home_filespace_write()` -- hardcoded paths / default args pointing
  outside `tempdir()` (`path.expand("~")`, `getwd()` as a default). Medium
  difficulty, best-effort only.
- `check_software_install()` -- `install.packages()`/`devtools::install_*`
  called outside a clearly-named installer function, or inside examples/
  tests/vignettes. Medium difficulty, needs location context.
- `check_core_count()` -- hardcoded core counts / uncapped
  `parallel::detectCores()` (`mc.cores`, `makeCluster(n)` literals). Medium
  difficulty, best-effort only.
- A static seed list of common non-R software/language names (e.g.
  "Python", "SQL", "JavaScript") to broaden `check_quoted_software_names()`
  beyond the linted package's own declared dependencies. Deferred from v1
  due to false-positive/maintenance risk; revisit if the narrower
  dependency-only version proves too conservative in practice.
- `check_verbose_output()` doesn't recognize two of the Cookbook's own
  accepted mitigations as exemptions: a `cat(..., file = ...)` call
  writing to a file/connection rather than the console, and a call gated
  behind a `verbose` argument (`if (verbose) cat(...)`). Revisit if these
  produce noisy false positives in practice.
- `check_option_restoration()` treats any `on.exit()` call in the same
  function frame as a valid restore, without checking it actually
  restores the same thing that changed, and doesn't check that the
  restore is registered immediately after the change (only that both
  exist somewhere in the same frame). Revisit if this proves too loose in
  practice.

## Canonical-source staleness

CRAN policy and the Cookbook are prose, not structured data, so checks can't
be auto-derived from them. Plan (not yet built): a periodic job (e.g. GitHub
Actions cron) that re-fetches the cached CRAN policy/Cookbook pages, diffs
against the last-seen copy, and flags when source text has changed so a
human can review whether an existing check needs updating. Each check's
`policy_reference` should link to the specific section/recipe it implements
plus a "last verified" date, so staleness is visible in the source itself.
