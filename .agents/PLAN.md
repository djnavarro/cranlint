# cranlint development plan

This document tracks scoped-out future development for cranlint -- work
that's been thought about but not done, or deliberately deferred. It is not
a changelog: once an item here is completed, its write-up should move to
[.agents/HISTORY.md](HISTORY.md) and be removed from this file rather than
marked "done" in place.

Last reviewed: 2026-08-27.

## Before implementing anything: settle the output contract

Every `check_*()` function needs to return a consistent shape so an
orchestrator can combine results. Decide and document (in `AGENTS.md`)
column names/types before writing the first check -- likely candidates:
`file`, `line`, `severity`, `message`, `policy_reference`.

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
4. `check_license_file()` -- `+ file LICENSE` referenced when the license
   type doesn't require an extra file (reference list from
   `R.home()`'s `share/licenses/license.db`).
5. `check_quoted_software_names()` -- package/API names (e.g. `python`,
   `ggplot2`) not wrapped in single quotes in Title/Description. Medium
   difficulty: needs a heuristic list of known software/package names:
   high false-positive risk, needs care.
6. `check_doi_formatting()` -- space after `doi:`/`https:` inside angle
   brackets, breaking auto-linking.

### Code checks

7. `check_hardcoded_seed()` -- `set.seed(<literal>)` inside function bodies
   (excluding `tests/`, `\examples`, `vignettes/`, where it's expected and
   recommended). This is the check that originally motivated the package.
8. `check_global_env_write()` -- `<<-` usage that could write to
   `.GlobalEnv`.
9. `check_installed_packages()` -- calls to `installed.packages()`, which
   should be `requireNamespace()`/`require()` instead.
10. `check_warn_suppression()` -- `options(warn = -1)`.
11. `check_verbose_output()` -- `print()`/`cat()` used for unsuppressable
    console output outside `print.*`/`format.*`/`summary.*` S3 methods.
12. `check_option_restoration()` -- `par()`/`options()`/`setwd()` changed
    without a paired `on.exit()` restore in the same function.
13. `check_dontrun_usage()` -- flags `\dontrun{}` for manual review (can't
    judge runnability automatically, so this should be a soft/review-level
    finding, not a hard fail).

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

## Canonical-source staleness

CRAN policy and the Cookbook are prose, not structured data, so checks can't
be auto-derived from them. Plan (not yet built): a periodic job (e.g. GitHub
Actions cron) that re-fetches the cached CRAN policy/Cookbook pages, diffs
against the last-seen copy, and flags when source text has changed so a
human can review whether an existing check needs updating. Each check's
`policy_reference` should link to the specific section/recipe it implements
plus a "last verified" date, so staleness is visible in the source itself.
