# geod

<!-- badges: start -->
[![R-CMD-check](https://github.com/diminutive/geod/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/diminutive/geod/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

R bindings to [Rust Geodesy](https://github.com/busstoptaktik/geodesy) by
Thomas Knudsen — a platform for experiments with geodetic transformations and
data flow. 

Very early, not for use yet. 

## Installation

Requires a Rust toolchain (`rustup`).

```r
remotes::install_github("diminutive/geod")
```

## Usage

```r
library(geod)

# What operators are available?
geod_ops()

# UTM zone 55 (Tasmania) — lon/lat in, easting/northing out
geod_apply("utm zone=55", x = c(147.3, 147.5), y = c(-42.9, -42.8))

# Same but as a matrix
geod_xy("utm zone=55", x = c(147.3, 147.5), y = c(-42.9, -42.8))

# Inverse: projected -> geographic
m <- geod_xy("utm zone=55", x = c(147.3, 147.5), y = c(-42.9, -42.8))
geod_xy("utm zone=55", x = m[, "x"], y = m[, "y"], inv = TRUE)

# Pipeline with adaptor ops
geod_apply("geo:in | utm zone=32 | neu:out", x = c(12., 18.), y = c(55., 59.))

# Validate a pipeline before using it
geod_validate("utm zone=55")          # TRUE
geod_validate("utm zone=banana")      # error string
```

## Related

- [Rust Geodesy](https://github.com/busstoptaktik/geodesy) — the upstream crate
- [reproj](https://github.com/hypertidy/reproj) — PROJ-based reprojection for R
- [geographiclib](https://github.com/hypertidy/geographiclib) — Karney geodesics for R


## Code of Conduct
  
Please note that the rgeodesy project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
