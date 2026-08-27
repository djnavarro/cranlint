# cranlint design history

This file is a condensed historical record of completed design decisions and
resolved issues: what was found, what was tried, and why a given choice was
made. It exists for context in future sessions, not as a changelog or PR
log. Current-state facts that came out of this history (what the package
looks like today) live in `AGENTS.md`, not here.

## Motivation and scope

Originated from recurring "silly" mistakes made across past personal CRAN
submissions (quote usage in DESCRIPTION, capitalisation, too-short
Description paragraphs, hardcoded `set.seed()` left in package code, etc.).
Considered candidate source material: the formal
[CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html),
ThinkR's [prepare-for-cran](https://github.com/ThinkR-open/prepare-for-cran)
guide, and the [CRAN Cookbook](https://contributor.r-project.org/cran-cookbook/).

Investigated `checkhelper` (the R package implementing much of ThinkR's
prepare-for-cran guidance) to avoid duplicating existing coverage. Findings:
it wraps `rcmdcheck`/`devtools::check()` with real CRAN check settings
(`check_as_cran()`), parses check output for no-visible-binding/missing-
import NOTEs (`get_no_visible()`, `print_globals()`), flags missing
`@return` tags (`find_missing_tags()`), and provides data-documentation
templates (`use_data_doc()`). It does **not** cover DESCRIPTION formatting,
hardcoded seeds, debug statements, encoding, or platform-specific code --
confirming a real gap for `cranlint` to fill, focused on the CRAN Cookbook's
"common problems" content rather than re-implementing `checkhelper`'s
orchestration/parsing role.

Decision: `cranlint` will call out to `checkhelper::check_as_cran()` and
wrap/rely on `lintr::T_and_F_symbol_linter()` rather than reimplementing
either. See `.agents/PLAN.md` for the full v1 check inventory drawn from the
CRAN Cookbook, and for what's explicitly out of scope (anything requiring
dynamic execution, like checktime or temp-directory detritus).

## Naming

Candidate names were checked with `available::available()` against CRAN,
Bioconductor, and GitHub. All of `cranaudit`, `cranlint`, `crancheckr`,
`precran`, `cranprep`, `cranhygiene`, `cranguard`, `readycran`, `crancop`,
`pkgpolish`, `fitforcran`, `cranpolish`, `cranscout`, `submitcheckr`, and
`cranfussy` were unclaimed. Chose **`cranlint`**: the `lint` suffix borrows
`lintr`'s well-understood convention (static source checks) more precisely
than an "audit"/"guard" framing would, and fits the package's actual design
(mostly regex/AST scans, not full `R CMD check` orchestration).

## Initial scaffolding

Created with `usethis::create_package()` at `~/GitHub/djnavarro/cranlint`,
matching conventions from sibling packages (`flametree`, `arttools`):
`Authors@R` with ORCID for Danielle Navarro, `MIT + file LICENSE`, UTF-8
encoding, roxygen2 with markdown enabled, testthat edition 3, git
initialized with an initial commit. No check functions have been written
yet -- see `.agents/PLAN.md` for the build order.

## Function naming: `cl_` prefix

Considered leaving check functions as bare `check_*()`, but that prefix is
extremely common across the ecosystem and cranlint is meant to be used
interactively alongside whatever else is loaded -- collisions/masking would
be a real nuisance even without CRAN-namespace concerns. Settled on
`cl_check_*()` (e.g. `cl_check_hardcoded_seed()`) for individual checks,
keeping `lint_cran()` unprefixed as the one top-level orchestrator entry
point, mirroring `lintr::lint()`.

## Output contract

Settled the shared return shape every `cl_check_*()` function must follow,
so `lint_cran()` can `dplyr::bind_rows()` results uniformly. Each check
returns a tibble with one row per finding (zero rows if clean), with
columns `check` (character, short id like `"hardcoded_seed"`), `file`
(character, path relative to package root), `line` (integer,
`NA_integer_` when not tied to a specific line), `severity` (ordered
factor), `message` (character), and `policy_reference` (character,
URL/citation).

For `severity`, considered mirroring `R CMD check`'s own vocabulary
(`note`/`warning`/`error`) but rejected it: that would misleadingly imply
cranlint findings are equivalent to actual check verdicts, when they're
static-analysis heuristics. Chose a cranlint-specific ordered scale instead:
`advisory` < `should_fix` < `must_fix`.

Also decided: no `column`-level field in v1 (no planned check needs
sub-line granularity yet), and no dedicated result S3 class yet (a plain
tibble is enough; a `cranlint_results` class with print/summary methods can
be added later at the `lint_cran()` orchestrator stage if useful).

Implemented as the internal helper `.cl_new_result()` in
`R/utils-result.R`, which validates `severity` values against the allowed
set and, called with no arguments, returns a correctly-typed zero-row
tibble -- the contract a check follows when it finds no issues. Added
`tibble` to `Imports` to support this. One gotcha surfaced while testing:
`tibble::tibble()` silently recycles a length-1 column down to 0 rows if
any other column passed is length-0, so `.cl_new_result()` callers must
always supply all six arguments together with consistent lengths, never
mixing an omitted (empty) default with populated arguments.

## First three checks: `description_length`, `title_case`, `authors_r`

Implemented the first batch of `cl_check_*()` functions, all DESCRIPTION-only
and sharing `desc`-based parsing (added `desc` to `Imports`, alongside a
`.cl_read_desc(path)` helper in `R/utils-desc.R`).

- `cl_check_description_length()`: flags a Description field with fewer
  than 2 sentences (heuristic regex sentence-splitter), per the Cookbook's
  ["Description Length"](https://contributor.r-project.org/cran-cookbook/general_issues.html#description-length)
  recipe, which explicitly asks for "a short paragraph (2+ sentences)".
- `cl_check_title_case()`: flags when `Title` differs from
  `tools::toTitleCase(Title)`, per the Cookbook's
  ["Title Case"](https://contributor.r-project.org/cran-cookbook/description_issues.html#title-case)
  recipe. Findings are worded as a prompt to review, not an instruction to
  blindly apply the suggestion, since `toTitleCase()` doesn't know about
  proper nouns or quoted software names that should keep their casing.
- `cl_check_authors_r()`: flags a missing `Authors@R` field, and flags
  manual `Author`/`Maintainer` fields that disagree with what R would
  generate from `Authors@R`, per the Cookbook's
  ["Using Authors@R"](https://contributor.r-project.org/cran-cookbook/description_issues.html#using-authorsr)
  recipe (CRAN treats such disagreement as an automatic rejection).

The `authors_r` mismatch comparison intentionally calls the same
non-exported base R helpers `R CMD check` itself uses to derive
`Author`/`Maintainer` from `Authors@R`
(`utils:::.format_authors_at_R_field_for_author()` and `...for_maintainer()`,
found by reading `tools:::.check_package_description_authors_at_R_field`,
the internal function that produces the real "Author field differs from
that derived from Authors@R" NOTE). This was a deliberate accuracy/fragility
trade-off: reimplementing the derivation heuristically risked false
positives/negatives, while calling the real internal logic is exact but
depends on unexported APIs that could change across R versions (confirmed
via `rcmdcheck::rcmdcheck()`: this produces exactly one NOTE, "Unexported
objects imported by ':::' calls", and no errors/warnings -- acceptable
since cranlint itself is not intended for CRAN submission). Both calls are
wrapped in `tryCatch()` so a future removal degrades to skipping the
match/mismatch comparison rather than erroring.

Fixtures live under `tests/testthat/fixtures/desc/<scenario>/DESCRIPTION`,
one minimal DESCRIPTION file per scenario (good, short-description,
bad-title, no-authors-r, authors-r-mismatch, authors-r-consistent).

## First code-scanning checks: `hardcoded_seed`, `global_env_write`, and shared R-file scanning infrastructure

Implemented the first two code-level checks, plus the shared infrastructure
future code checks will reuse (`R/utils-scan.R`):

- `.cl_list_r_files(path)` -- lists `.R` files under a package's `R/`
  directory only. This single scoping decision is what satisfies the
  "excluding `tests/`, `\examples`, `vignettes/`" exclusion called for in
  `.agents/PLAN.md`'s `hardcoded_seed` write-up, since code checks never
  look outside `R/` in the first place -- no extra exclusion logic needed.
- `.cl_parse_r_file()` / `.cl_scan_r_files(path)` -- parse each file with
  `parse(keep.source = TRUE)` and `utils::getParseData(includeText = TRUE)`,
  returning a named list of per-file parse-data frames (one file's parse
  tree can't be safely combined with another's into one data frame, since
  `id`/`parent` values are only meaningful within a single file's tree). A
  file with a syntax error is skipped with a `warning()` rather than
  aborting the whole scan.
- `.cl_find_calls(pd, fun_names)` / `.cl_call_arg_texts(pd, call_row)` --
  generic helpers for finding calls to a named function and extracting the
  source text of each argument expression, reusable by any future check
  that needs to inspect call arguments (e.g. a later
  `check_core_count()`).

Chose token-based parsing (`getParseData()`) over regex scanning
specifically to avoid false positives from comments/strings containing
text that looks like a flagged call (e.g. a comment reading
`# set.seed(42) is bad`) -- the parser's tokenizer naturally excludes
comment/string contents from `SYMBOL_FUNCTION_CALL` tokens. This mirrors
how `lintr` avoids the same false-positive class.

`cl_check_hardcoded_seed()` flags `set.seed()` calls where any argument's
source text matches a numeric-literal pattern (positional or named,
optionally signed, optional `L` suffix), per the Cookbook's
["Setting a Specific Seed"](https://contributor.r-project.org/cran-cookbook/code_issues.html#setting-a-specific-seed)
recipe. Severity `should_fix`, since the recipe is a strong, consistent
CRAN reviewer request rather than a written policy violation.

`cl_check_global_env_write()` flags `<<-`/`->>` usage (both share the
`LEFT_ASSIGN`/`RIGHT_ASSIGN` token type in `getParseData()`'s output; only
the `text` field distinguishes them from `<-`/`->`), per the Cookbook's
["Writing to the .GlobalEnv"](https://contributor.r-project.org/cran-cookbook/code_issues.html#writing-to-the-.globalenv)
recipe. Severity `must_fix`, since the Cookbook states plainly that
modifying `.GlobalEnv` "is not allowed by the CRAN policies" -- stronger
language than the seed recipe. Known limitation, not handled in v1: a
`<<-` that only reaches a known parent scope (e.g. inside a closure
factory) is technically safe, and the Cookbook notes 'shiny' packages are
sometimes excepted; distinguishing these would need real scope analysis,
so every use is flagged for manual review instead.

Fixtures live under `tests/testthat/fixtures/code/<scenario>/R/*.R`,
mirroring the `fixtures/desc/<scenario>/DESCRIPTION` pattern used for the
DESCRIPTION checks.

## `installed_packages` and `warn_suppression`, plus named-argument support in the scan helpers

Implemented `cl_check_installed_packages()` and `cl_check_warn_suppression()`,
both simple call-site checks reusing `.cl_find_calls()`.

`cl_check_installed_packages()` flags any `installed.packages()` call in
`R/`, per the Cookbook's
["Calling installed.packages()"](https://contributor.r-project.org/cran-cookbook/code_issues.html#calling-installed.packages)
recipe. Severity `should_fix` (a "do not use" recommendation, not phrased
as an outright policy violation like the two checks below).

`cl_check_warn_suppression()` flags `options()` calls with a negative
`warn` value, per the Cookbook's
["Setting options(warn = -1)"](https://contributor.r-project.org/cran-cookbook/code_issues.html#setting-optionswarn--1)
recipe, which states plainly "this is not allowed." Severity `must_fix`,
matching `global_env_write`'s reasoning. Needed to distinguish `warn = -1`
from other `options()` arguments by name, which the existing
`.cl_call_arg_texts()` helper (used by `hardcoded_seed`, positional-only)
couldn't do. Added `.cl_call_args(pd, call_row)` to `R/utils-scan.R`,
returning a `name`/`text` data frame per argument (name is `""` for
positional arguments) by walking a call's child parse-tree nodes in source
order and pairing each `SYMBOL_SUB` (argument name) token with the `expr`
node that follows it. Refactored `.cl_call_arg_texts()` to be a thin
wrapper (`.cl_call_args(pd, call_row)$text`) so `hardcoded_seed` didn't
need to change.

## `lint_cran()` orchestrator

Implemented `lint_cran(path = ".")`, the single top-level entry point that
runs all seven `cl_check_*()` functions (in `.agents/PLAN.md`'s build
order: the three DESCRIPTION checks, then the four code checks) and
combines their results.

Decided to combine results with base `rbind()` rather than adding a
dependency (`dplyr::bind_rows()` or `vctrs::vec_rbind()`): every check
already returns the identical schema from `.cl_new_result()`, including
the same `severity` factor levels, so `rbind()` on same-shaped tibbles
works cleanly with no coercion surprises (verified directly, including
rbinding zero-row results).

Decided that per-check errors are **not** caught -- if a check errors
(e.g. `path` has no `DESCRIPTION` at all), `lint_cran()` lets the error
propagate rather than swallowing it into a result row, since that signals
something more fundamental than an individual finding worth flagging. This
is a different tier from a single malformed R file, which is already
handled gracefully further down (`.cl_scan_r_files()` skips it with a
warning without stopping the other checks).

Returns a plain tibble, no new S3 class -- deferred again pending an
actual need (e.g. a print method grouping findings by severity), per the
original output-contract decision.

## Moving to the `.agents/` folder structure

Following the pattern established across other packages (`emaxnls`,
`erglm`, `quartose`), agent-facing documentation is split three ways from
the start: `AGENTS.md` at the project root stays a lean, current-state
reference; scoped-out future work (including the full v1 check inventory)
lives in `.agents/PLAN.md`; and this file holds the resolved-decision
record. All three are excluded from the built package via `.Rbuildignore`.
