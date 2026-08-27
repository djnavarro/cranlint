test_that(".cl_expected_author formats persons as CRAN would derive Author", {
  # .cl_expected_author() normalizes whitespace (collapsing the ",\n  "
  # separator to a single space) so it compares cleanly against a manually
  # line-wrapped DESCRIPTION field.
  persons <- as.person(c(
    "Jane Doe <jane@example.com> [aut, cre]",
    "Bob Smith [aut]"
  ))
  expect_equal(
    .cl_expected_author(persons),
    "Jane Doe [aut, cre], Bob Smith [aut]"
  )
})

test_that(".cl_expected_maintainer formats the sole cre person as CRAN would derive Maintainer", {
  persons <- as.person(c(
    "Jane Doe <jane@example.com> [aut, cre]",
    "Bob Smith [aut]"
  ))
  expect_equal(.cl_expected_maintainer(persons), "Jane Doe <jane@example.com>")
})

test_that(".cl_expected_maintainer returns NA when there's no cre person", {
  persons <- as.person("Bob Smith [aut]")
  expect_true(is.na(.cl_expected_maintainer(persons)))
})

test_that(".cl_expected_maintainer returns NA when there's more than one cre person", {
  persons <- as.person(c(
    "Jane Doe <jane@example.com> [cre]",
    "Bob Smith <bob@example.com> [cre]"
  ))
  expect_true(is.na(.cl_expected_maintainer(persons)))
})
