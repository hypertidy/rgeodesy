test_that("UTM matches Rust Geodesy's documented reference values", {
  # From the Rust Geodesy README: Copenhagen (12E, 55N) and Stockholm (18E, 59N)
  # through "utm zone=33".
  cph <- geod_apply("gis:in | utm zone=33", x = 12, y = 55)
  sth <- geod_apply("gis:in | utm zone=33", x = 18, y = 59)
  expect_equal(cph$x, 308124.367860, tolerance = 1e-5)
  expect_equal(cph$y, 6098907.825005, tolerance = 1e-5)
  expect_equal(sth$x, 672319.964088, tolerance = 1e-5)
  expect_equal(sth$y, 6543920.334128, tolerance = 1e-5)
})

test_that("output is a list of x and y with the input length", {
  r <- geod_apply("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
  expect_type(r, "list")
  expect_named(r, c("x", "y"))
  expect_length(r$x, 2)
  expect_length(r$y, 2)
})

test_that("forward then inverse round-trips to the input", {
  lon <- c(147.3, 12, 18)
  lat <- c(-42.9, 55, 59)
  op  <- "gis:in | utm zone=33"
  fwd <- geod_apply(op, x = lon, y = lat)
  back <- geod_apply(op, x = fwd$x, y = fwd$y, inv = TRUE)
  expect_equal(back$x, lon, tolerance = 1e-7)
  expect_equal(back$y, lat, tolerance = 1e-7)
})

test_that("gis:in (lon, lat) and geo:in (lat, lon) agree when args are swapped", {
  gis <- geod_apply("gis:in | utm zone=55 south", x = 147.3, y = -42.9)
  geo <- geod_apply("geo:in | utm zone=55 south", x = -42.9, y = 147.3)
  expect_equal(gis$x, geo$x)
  expect_equal(gis$y, geo$y)
})

test_that("several projection families run and round-trip", {
  lon <- 12; lat <- 55
  projections <- c(
    "merc",
    "webmerc",
    "lcc lat_0=52 lat_1=33 lat_2=45",
    "laea lat_0=52 lon_0=10",
    "tmerc lon_0=9"
  )
  for (p in projections) {
    op <- paste("gis:in |", p)
    fwd <- geod_apply(op, x = lon, y = lat)
    # projected coordinates should be finite metres, not geographic degrees
    expect_true(is.finite(fwd$x) && is.finite(fwd$y), info = op)
    back <- geod_apply(op, x = fwd$x, y = fwd$y, inv = TRUE)
    expect_equal(back$x, lon, tolerance = 1e-6, info = op)
    expect_equal(back$y, lat, tolerance = 1e-6, info = op)
  }
})

test_that("a bad pipeline raises an R error with a useful message", {
  expect_error(geod_apply("utm zone=banana", x = 1, y = 1), "zone")
  expect_error(geod_apply("not_a_real_operator", x = 1, y = 1), "not found")
})

test_that("the bare 'pipeline' operator raises an error instead of crashing", {
  expect_error(geod_apply("pipeline", x = 1, y = 1), "not supported")
})

test_that("mismatched x and y lengths raise an error", {
  expect_error(geod_apply("utm zone=33", x = 1:3, y = 1:2), "same length")
})

test_that("op_str must be a scalar string", {
  expect_error(geod_apply(c("a", "b"), x = 1, y = 1), "single")
  expect_error(geod_apply(NA_character_, x = 1, y = 1), "single")
})

test_that("geod_xy() returns a two-column matrix", {
  m <- geod_xy("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
  expect_true(is.matrix(m))
  expect_equal(dim(m), c(2L, 2L))
  expect_equal(colnames(m), c("x", "y"))

  # geod_xy() and geod_apply() must agree.
  r <- geod_apply("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
  expect_equal(m[, "x"], r$x)
  expect_equal(m[, "y"], r$y)
})
