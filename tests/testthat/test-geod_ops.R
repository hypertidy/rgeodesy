test_that("geod_ops() returns a sorted, non-empty character vector", {
  ops <- geod_ops()
  expect_type(ops, "character")
  expect_gt(length(ops), 0)
  expect_false(any(is.na(ops)))
  expect_identical(ops, sort(ops))
  expect_false(any(duplicated(ops)))
})

test_that("geod_ops() contains the documented operator families", {
  ops <- geod_ops()
  projections <- c("utm", "tmerc", "merc", "webmerc", "lcc", "laea", "omerc", "somerc")
  transforms  <- c("cart", "helmert", "molodensky", "gridshift", "deformation")
  adaptors    <- c("geo:in", "geo:out", "gis:in", "gis:out",
                   "neu:in", "neu:out", "enu:in", "enu:out")
  expect_true(all(projections %in% ops))
  expect_true(all(transforms %in% ops))
  expect_true(all(adaptors %in% ops))
})

test_that("geod_ops() excludes operators not present in geodesy 0.15", {
  ops <- geod_ops()
  # These were listed by the previous hard-coded set but are not registered.
  expect_false(any(c("hgridshift", "vgridshift", "geoid", "horner",
                     "affine", "latshift", "proj", "namepipes", "normalize") %in% ops))
})

test_that("every operator reported by geod_ops() is actually registered", {
  ops <- geod_ops()
  # Drop the one known crasher that cannot be validated in-process.
  ops <- setdiff(ops, "pipeline")
  not_found <- vapply(ops, function(op) {
    res <- geod_validate(op)
    is.character(res) && grepl("not found", res, fixed = TRUE)
  }, logical(1))
  expect_false(any(not_found), info = paste(names(not_found)[not_found], collapse = ", "))
})
