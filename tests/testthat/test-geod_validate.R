test_that("valid pipelines return TRUE", {
  expect_true(geod_validate("gis:in | utm zone=55 south"))
  expect_true(geod_validate("utm zone=32"))
  expect_true(geod_validate("gis:in | merc | gis:out"))
})

test_that("invalid pipelines return an informative error string", {
  res <- geod_validate("utm zone=banana")
  expect_type(res, "character")
  expect_match(res, "zone")

  res2 <- geod_validate("not_a_real_operator")
  expect_type(res2, "character")
  expect_match(res2, "not found")
})

test_that("the bare 'pipeline' operator is guarded, not fatal", {
  # Compiling a bare `pipeline` recurses infinitely in Rust Geodesy and would
  # otherwise take down the R session with a C stack overflow.
  res <- geod_validate("pipeline")
  expect_type(res, "character")
  expect_match(res, "not supported")

  # Also guarded when it appears as a step within a pipeline string.
  expect_match(geod_validate("gis:in | pipeline"), "not supported")
})

test_that("geod_validate() rejects non-scalar input", {
  expect_error(geod_validate(c("utm", "merc")), "single")
  expect_error(geod_validate(NA_character_), "single")
  expect_error(geod_validate(42), "single")
})
