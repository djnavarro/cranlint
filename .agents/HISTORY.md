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

## Moving to the `.agents/` folder structure

Following the pattern established across other packages (`emaxnls`,
`erglm`, `quartose`), agent-facing documentation is split three ways from
the start: `AGENTS.md` at the project root stays a lean, current-state
reference; scoped-out future work (including the full v1 check inventory)
lives in `.agents/PLAN.md`; and this file holds the resolved-decision
record. All three are excluded from the built package via `.Rbuildignore`.
