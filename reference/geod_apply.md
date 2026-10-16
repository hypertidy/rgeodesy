# Apply a Rust Geodesy pipeline to coordinate vectors

Compiles the pipeline once and applies it, vectorised, to all coordinate
pairs. Coordinates follow Rust Geodesy conventions: geographic data must
be bracketed with an adaptor operator (`gis:in`/`gis:out` for
`(lon, lat)` in degrees, or `geo:in`/`geo:out` for `(lat, lon)`),
because RG works internally in radians.

## Usage

``` r
geod_apply(op_str, x, y, inv = FALSE)
```

## Arguments

- op_str:

  Character scalar. A Rust Geodesy pipeline string, e.g.
  `"gis:in | utm zone=32"`.

- x:

  Numeric vector. First coordinate (longitude/easting under the GIS
  convention).

- y:

  Numeric vector. Second coordinate (latitude/northing). Must be the
  same length as `x`.

- inv:

  Logical scalar. Run the inverse operation. Default `FALSE`.

## Value

A named list with numeric elements `x` and `y`, each the same length as
the input.

## See also

[`geod_xy()`](https://hypertidy.github.io/rgeodesy/reference/geod_xy.md)
for matrix output,
[`geod_validate()`](https://hypertidy.github.io/rgeodesy/reference/geod_validate.md),
[`geod_ops()`](https://hypertidy.github.io/rgeodesy/reference/geod_ops.md)

Other rgeodesy functions:
[`geod_ops()`](https://hypertidy.github.io/rgeodesy/reference/geod_ops.md),
[`geod_validate()`](https://hypertidy.github.io/rgeodesy/reference/geod_validate.md),
[`geod_xy()`](https://hypertidy.github.io/rgeodesy/reference/geod_xy.md)

## Examples

``` r
# Geographic (lon, lat) in degrees -> UTM zone 55 south (easting, northing)
geod_apply("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
#> $x
#> [1] 524492.1 540886.1
#> 
#> $y
#> [1] 5250246 5261273
#> 

# Round trip: forward then inverse recovers the input
fwd <- geod_apply("gis:in | utm zone=55 south", x = 147.3, y = -42.9)
geod_apply("gis:in | utm zone=55 south", x = fwd$x, y = fwd$y, inv = TRUE)
#> $x
#> [1] 147.3
#> 
#> $y
#> [1] -42.9
#> 

# Multi-step pipeline: geographic in, northing-easting-up out
geod_apply("gis:in | utm zone=32 | neu:out", x = c(12, 18), y = c(55, 59))
#> $x
#> [1] 6098908 6574904
#> 
#> $y
#> [1]  691875.6 1016066.6
#> 
```
