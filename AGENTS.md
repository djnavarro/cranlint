
# AGENTS.md

## What this package does

`cranlint` is a personal-use static checker for common mistakes made when
preparing an R package for CRAN submission. It scans a package's source tree
(DESCRIPTION, R/, man/, examples, vignettes) for issues the author has
personally been tripped up by in past submissions, and complements
(rather than duplicates) existing tools:

- **`checkhelper`** already wraps `rcmdcheck`/`devtools::check()` with real
  CRAN check settings (`check_as_cran()`), parses check output for
  no-visible-binding/missing-import NOTEs, and flags missing `@return` tags.
  `cranlint` does not reimplement any of this -- it either calls out to
  `checkhelper` directly or skips checks it already covers.
- **`lintr`** already has a `T_and_F_symbol_linter`; `cranlint` doesn't
  reimplement `T`/`F` detection either.
- **`spelling`** and **`urlchecker`** cover spelling and URL validity.

`cranlint`'s niche is the more nuanced, easy-to-miss issues catalogued in the
[CRAN Cookbook](https://contributor.r-project.org/cran-cookbook/) that aren't
covered by any of the above -- e.g. hardcoded `set.seed()` calls left in
package code, DESCRIPTION quoting/capitalisation/length issues, writes to
`.GlobalEnv`, `options(warn = -1)`, and similar. See
[.agents/PLAN.md](.agents/PLAN.md) for the full v1 check inventory and build
order; nothing has been implemented yet.

This package is not itself intended for CRAN submission, but its name must
still not collide with an existing CRAN/Bioconductor package (confirmed via
`available::available()` at the time of naming).

---

## Architecture reference (current state)

This section documents how the package works *today*. For the design
rationale behind decisions, rejected alternatives, and a record of how the
API got here, see [.agents/HISTORY.md](.agents/HISTORY.md).

### Package structure

The v1 check inventory (see [.agents/HISTORY.md](.agents/HISTORY.md) for
design write-ups) is fully implemented: twelve `cl_check_*()` functions
covering DESCRIPTION issues (`description_length`, `title_case`,
`authors_r`, `license_file`, `doi_formatting`, `quoted_software_names`,
`quoted_function_names`) and code/doc issues (`hardcoded_seed`,
`global_env_write`, `installed_packages`, `warn_suppression`,
`verbose_output`, `option_restoration`, `dontrun_usage`), run together
by the `lint_cran()` orchestrator.

Structure:

```
R/
  check-<name>.R      # One file per check function (e.g. check-hardcoded-seed.R,
                       # check-description-length.R), each exporting a
                       # cl_check_<name>() function
  lint-cran.R          # Orchestrator that runs all checks and combines
                       # their output: lint_cran(), mirroring lintr::lint()
  utils-desc.R         # Shared helpers for DESCRIPTION-based checks
  utils-scan.R         # Shared helpers for parsing/walking R/ source (via
                       # utils::getParseData())
  utils-man.R          # Shared helpers for scanning man/*.Rd files
  utils-result.R        # .cl_new_result(), the check-output constructor
tests/testthat/
  test-check-<name>.R  # One test file per check function, using small
                       # fixture packages/files under tests/testthat/fixtures/
```

### Output contract

Every `cl_check_*()` function returns a tibble with one row per finding
(zero rows if the check finds nothing), always with these columns:

| Column             | Type            | Notes                                                                 |
|--------------------|-----------------|------------------------------------------------------------------------|
| `check`            | character       | Short id of the check, e.g. `"hardcoded_seed"`.                        |
| `file`             | character       | Path relative to the package root, e.g. `"R/foo.R"` or `"DESCRIPTION"`.|
| `line`             | integer         | `NA_integer_` when a finding isn't tied to a specific line.            |
| `severity`         | ordered factor  | One of `"advisory"` < `"should_fix"` < `"must_fix"` (increasing urgency; a cranlint-specific scale, not `R CMD check`'s note/warning/error, since these are static-analysis heuristics rather than actual check verdicts). |
| `message`          | character       | Human-readable description of the specific instance found.             |
| `policy_reference` | character       | URL/citation to the CRAN policy or Cookbook recipe motivating the check.|

Construct these tibbles via the internal helper `.cl_new_result()`
(`R/utils-result.R`), which validates `severity` values and produces a
correctly-typed zero-row tibble when called with no arguments -- this is
the contract every check should follow when it finds no issues, so
`dplyr::bind_rows()` in the orchestrator always works uniformly. There is
no `column`-level field or dedicated result S3 class in v1; both can be
added later (the latter likely at the `lint_cran()` orchestrator stage) if
a concrete need arises.

### Naming conventions (planned)

- Check functions: `cl_check_<topic>()`, e.g. `cl_check_hardcoded_seed()`,
  `cl_check_description_length()`. The `cl_` prefix (short for cranlint)
  avoids masking/collisions with the many other packages that export a bare
  `check_*()` -- relevant since cranlint is meant to be used interactively
  alongside whatever else is loaded, not called via `::`.
- Orchestrator: `lint_cran()` is the one exception left unprefixed, as the
  single top-level entry point (mirroring `lintr::lint()`).
- Internal helpers: dot-prefixed, e.g. `.scan_r_files()`.

---

## Development workflow

- Documentation generated with roxygen2 (markdown enabled).
- Standard devtools workflow: `devtools::load_all()`, `devtools::document()`,
  `devtools::test()`, `devtools::check()`.
- Testing uses testthat edition 3.

### Generated files -- do not edit directly

`NAMESPACE` and all files under `man/` are generated by roxygen2. Edit the
roxygen source in `R/` and regenerate with `devtools::document()`.

---

## Assistant preferences

### Autonomy

- For **structural decisions** (the shared check-output format, the
  orchestrator API, which Cookbook items are in/out of scope) propose a plan
  and get explicit sign-off before writing code -- these are exactly the
  kinds of decisions this file exists to record once made.
- Individual check functions, once the output contract is settled, can be
  implemented directly without a check-in per function.
- After making code changes, run `devtools::test()` to verify nothing is
  broken.

### Dependencies

- Keep dependencies minimal. Ask before adding any new dependency to
  `Imports` or `Suggests` in `DESCRIPTION`.

### Commit messages

- Use freeform imperative mood: "Add x", "Fix y", "Remove z". No
  conventional-commit prefix required.

---

## Keeping this documentation current

This file (`AGENTS.md`) should stay a lean, current-state reference -- if a
change makes something above inaccurate, update it in place rather than
appending a note about the change.

Two companion files in `.agents/` (also excluded from the built package via
`.Rbuildignore`) carry the parts that don't belong here:

- **[.agents/HISTORY.md](.agents/HISTORY.md)** -- a condensed record of
  completed design decisions and their rationale (what was tried, rejected,
  and why), for context in future sessions. When you finish a piece of
  nontrivial design work, add an entry here rather than growing this file
  with "used to be X, now Y" narrative.
- **[.agents/PLAN.md](.agents/PLAN.md)** -- scoped-out future work and
  deferred/open items, including the full v1 check inventory. When you
  finish something listed there, move its write-up into `HISTORY.md` and
  remove it from `PLAN.md` rather than marking it "done" in place.
