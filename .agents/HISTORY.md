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

The `authors_r` mismatch comparison originally called the same non-exported
base R helpers `R CMD check` itself uses to derive `Author`/`Maintainer`
from `Authors@R` (`utils:::.format_authors_at_R_field_for_author()` and
`...for_maintainer()`, found by reading
`tools:::.check_package_description_authors_at_R_field`, the internal
function that produces the real "Author field differs from that derived
from Authors@R" NOTE). This was superseded (see "Replacing `:::` calls"
below) after the resulting `R CMD check` NOTE turned out to fail CI, which
runs `R CMD check` on cranlint itself even though cranlint isn't meant for
CRAN submission.

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

## Replacing `:::` calls in `authors_r` with exported `format()`

The original `authors_r` mismatch comparison (see above) called two
non-exported `utils:::` helpers, accepting a single `R CMD check` NOTE as
a deliberate trade-off. In practice this NOTE made CI's `R CMD check` step
fail on every run, which isn't acceptable even for a non-CRAN package with
its own CI. Replaced both calls with a from-scratch reimplementation using
only the exported `format()` S3 generic for `person` objects:

- `.cl_expected_author(persons)`: formats each person as
  `format(person, include = c("given", "family", "role"))` (deliberately
  omitting `email`, which the real `Author` field never includes) and
  joins them with `",\n  "` -- verified byte-for-byte identical to
  `utils:::.format_authors_at_R_field_for_author()`'s output across the
  cases tested (multiple authors, roles, with/without email).
- `.cl_expected_maintainer(persons)`: filters to the person(s) with role
  `"cre"`, and if there's exactly one, formats them as
  `format(person, include = c("given", "family", "email"))` -- likewise
  verified identical to `utils:::.format_authors_at_R_field_for_maintainer()`.
  Returns `NA` (skipping the comparison) if there's zero or more than one
  `"cre"` person, mirroring how the internal check itself declines to
  produce a comparable `Maintainer` value in the same situations.

Both live in `R/utils-desc.R` alongside `.cl_read_desc()`. `R CMD check`
now runs clean (0 errors, 0 warnings, 0 notes). This is a closer parity
than the earlier trade-off assumed was necessary -- `format()` on `person`
objects turned out to already expose exactly the building blocks the
internal helpers use, so no accuracy was given up by dropping `:::`.

## Moving to the `.agents/` folder structure

Following the pattern established across other packages (`emaxnls`,
`erglm`, `quartose`), agent-facing documentation is split three ways from
the start: `AGENTS.md` at the project root stays a lean, current-state
reference; scoped-out future work (including the full v1 check inventory)
lives in `.agents/PLAN.md`; and this file holds the resolved-decision
record. All three are excluded from the built package via `.Rbuildignore`.

## `check_license_file()` and `check_doi_formatting()`

Implemented the two remaining straightforward DESCRIPTION checks from the
v1 inventory (`check_quoted_software_names()` was deferred pending a
separate design discussion of its heuristic word-list approach).

- `cl_check_license_file()` flags a `License` field ending in
  `+ file LICENSE` where the base license isn't one of the three CRAN
  templates that actually require the extra file. The templated set (`MIT`,
  `BSD_2_clause`, `BSD_3_clause`) was derived by reading
  `R.home()`'s `share/licenses/license.db` and filtering to rows whose
  `Note` column reads "this is a template, needs + file LICENSE" -- these
  three abbreviations are the only ones with that note. A `LICENSE` file
  can legitimately be needed for other licenses too (attribution
  requirements, extra restrictions), which static analysis can't detect,
  so the check is scoped only to the "unnecessary reference" direction
  named in the plan, not the reverse (missing file when required).
- `cl_check_doi_formatting()` scans the `Description` field for `<...>`
  spans that look like a `doi:`/`https:` reference and flags whitespace
  right after the opening `<` or right after the `doi:`/`https:` prefix,
  either of which breaks CRAN's auto-linking. This is a text-matching
  heuristic on bracket contents, not a real URL/DOI validator.

Both follow the existing DESCRIPTION-check pattern: `line` is always
`NA_integer_` (findings aren't tied to a specific line in the raw file),
and severity is `should_fix` for both (review-and-fix, not an automatic
CRAN rejection like the `authors_r` mismatch case).

## `check_quoted_software_names()` and `check_quoted_function_names()`

Split the plan's single `check_quoted_software_names()` item into two
checks after design discussion, since the two failure modes (a real
software name left unquoted vs. a function name mistakenly quoted) need
different candidate word lists and warrant different confidence levels.

Design decisions (confirmed with the user before implementation):

- **Candidate list for under-quoting is limited to the linted package's
  own declared dependencies** (`Depends`/`Imports`/`Suggests`/
  `LinkingTo` via `desc::get_deps()`, excluding `"R"`), not a general
  static list of known software/language names (e.g. "Python", "SQL").
  This keeps precision high and needs no external data, at the cost of
  under-reporting (it won't catch an unquoted "Python"). A static seed
  list was considered and explicitly rejected for v1 due to false-positive
  and maintenance risk -- worth revisiting later if the narrow version
  proves too conservative in practice.
- **Function-name candidates for over-quoting come from two sources**:
  (a) functions defined anywhere in the linted package's own `R/` files,
  found by walking parse data for any `<-`/`=` assignment (at any nesting
  level, not just top-level) whose right-hand side is a `function(...)`
  expression (`.cl_extract_function_names()`/`.cl_defined_function_names()`
  in `R/utils-scan.R`); and (b) exported functions from `base`, `stats`,
  `utils`, and `methods`, looked up via `getNamespaceExports()` +
  `asNamespace()` rather than the search path, so the result doesn't
  depend on whether those packages happen to be attached in the calling
  session (`.cl_base_function_names()`, also in `utils-scan.R`). Neither
  source needed a new dependency.
- **Severity**: `advisory` for missing quotes (a plain word matching a
  dependency name doesn't always refer to the package), `should_fix` for
  a quoted function name (a much more specific, higher-confidence mistake
  signal).

Implementation notes:

- Quoted-token extraction (`.cl_quoted_tokens()` in `R/utils-desc.R`) uses
  a lookaround regex `(?<=')[A-Za-z][\w.:]*(\(\))?(?=')` to pull out
  single-word tokens (with an optional trailing `()`) wrapped in literal
  `'`. This is a known-limited heuristic: a quoted phrase containing an
  English contraction (e.g. `'don't'`) can get its internal apostrophe
  misread as a quote boundary, splitting the token. Considered acceptable
  since Titles/Descriptions rarely quote contracted phrases.
- Unquoted-occurrence detection (`.cl_has_unquoted_occurrence()`, also in
  `utils-desc.R`) matches a candidate name as a whole word (`\b`-bounded,
  escaped via `.cl_regex_escape()`) and only treats an occurrence as
  already-quoted when a literal `'` directly precedes and follows the
  match -- no internal space, matching CRAN's own convention.
- `.cl_extract_function_names()` walks assignment siblings ordered by
  `(line1, col1)` rather than `getParseData()`'s `id` column to find the
  LHS/RHS neighbors of an assignment token -- `id` order does not track
  source position (verified empirically: in `foo <- function(x) x + 1`,
  the LHS `expr` node for `foo` gets a higher `id` than the `<-` token
  that follows it in the source).

## `check_verbose_output()`

Implemented the first of the three remaining code checks. Flags `print()`/
`cat()` calls in `R/` that aren't nested inside a function whose name
matches `^(print|format|summary)\.` (the S3 method naming convention),
per the CRAN Cookbook's exemption for "printing in special functions like
print, summary, ... or methods for generic functions".

Needed a more general enclosing-function lookup than existing checks had,
since a call can be nested arbitrarily deep (including inside anonymous
helpers, e.g. `lapply(x, function(z) print(z))`) and the check needs to
know whether *any* named ancestor function is an exempt S3 method, not
just the innermost one. Added to `R/utils-scan.R`:

- `.cl_function_assignments()` -- a generalization of the existing
  `.cl_extract_function_names()` that also returns the parse-data `id` of
  each function-valued assignment's RHS `expr`, not just its name.
  `.cl_extract_function_names()` is now a one-line wrapper around it,
  behavior-preserving (verified via the existing `quoted_function_names`
  tests, which depend on it transitively).
- `.cl_enclosing_function_names()` -- walks a parse-data row's `parent`
  chain to the top of the file, and for every ancestor `id` that is a
  function-definition `expr` (detected the same way as elsewhere in this
  codebase: `any(pd$parent == id & pd$token == "FUNCTION")`), looks up its
  name via `.cl_function_assignments()`. Anonymous functions in the chain
  contribute no name but don't stop the walk, so a call several layers
  deep still surfaces the nearest *named* enclosing function. A top-level
  call (no enclosing function at all) correctly returns `character(0)`,
  which the check treats as "not exempt" -- print/cat with no enclosing
  function is a real, arguably worse violation (unconditional output on
  load/attach), not something to skip.

  One implementation pitfall hit during testing: looking up a name via
  `fn_names[[as.character(id)]]` (double-bracket) throws "subscript out
  of bounds" for anonymous functions with no matching entry; switched to
  `unname(fn_names[as.character(id)])` (single-bracket, returns `NA` for
  a missing name) instead.

Known, documented limitations (over-reporting relative to what CRAN
actually requires): a `cat(..., file = ...)` call writing to a
file/connection rather than the console is still flagged, since the
check doesn't inspect `cat()`'s arguments; and the Cookbook's other
accepted mitigation -- gating the call behind a `verbose` argument, e.g.
`if (verbose) cat(...)` -- isn't recognized as an exemption either.
Both are called out in the function's docstring rather than silently
handled.

## `check_option_restoration()`

Implemented the second of the two remaining code checks. Flags
`par()`/`options()`/`setwd()` calls in `R/` that change state without a
paired `on.exit()` restore in the same function frame.

Reused `.cl_call_args()` (already built for `warn_suppression`) to
inspect a call's arguments and decide whether it's a state *change* at
all, via a new `.cl_is_state_change()`:

- `setwd()` always counts (no query form exists).
- A bare `par()`/`options()` call, or one with only unnamed/positional
  arguments (e.g. `par("mfrow")`, or `par(oldpar)`/`options(oldopts)`
  restoring a previously-saved list), is treated as a query/restore, not
  a change.
- `par(no.readonly = TRUE)` specifically is excluded even though it has a
  named argument, since it's the standard snapshot-for-later-restore
  idiom the Cookbook itself recommends (`oldpar <- par(no.readonly =
  TRUE)`), not a change by itself.
- Anything else with at least one named argument counts as a change.

Added `.cl_innermost_enclosing_function_id()` to `R/utils-scan.R` --
similar to `.cl_enclosing_function_names()` (added for `verbose_output`)
but returns the nearest enclosing function regardless of whether it's
named, since what matters here is the function *frame* `on.exit()` needs
to share, not what the function is called. Used both to find the frame a
change happens in, and (via a new `.cl_onexit_frame_ids()` in
`check-option-restoration.R`) to find which frames contain an `on.exit()`
call at all. A change is exempt if its frame id is in that set.

This correctly isolates nested functions from each other during testing:
an `on.exit()` inside a nested helper function does *not* exempt a
`par()`/`options()`/`setwd()` change in the outer function that defines
the helper, since they're different frames -- verified with a
`nested_bad()` fixture case.

Known, documented coarseness (two ways this under- or over-reports):
presence of *any* `on.exit()` call in the same frame counts as a restore,
without checking it actually restores the same thing that was changed;
and ordering (the Cookbook says the restore should be registered
*immediately* after the change) isn't checked either, only that both
calls exist somewhere in the same frame.
