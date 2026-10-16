# Apply a pipeline and return a two-column matrix

Convenience wrapper around
[`geod_apply()`](https://hypertidy.github.io/rgeodesy/reference/geod_apply.md)
that returns a numeric matrix with columns `x` and `y` rather than a
list.

## Usage

``` r
geod_xy(op_str, x, y, inv = FALSE)
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

A numeric matrix with columns `x` and `y`, one row per input point.

## See also

Other rgeodesy functions:
[`geod_apply()`](https://hypertidy.github.io/rgeodesy/reference/geod_apply.md),
[`geod_ops()`](https://hypertidy.github.io/rgeodesy/reference/geod_ops.md),
[`geod_validate()`](https://hypertidy.github.io/rgeodesy/reference/geod_validate.md)

## Examples

``` r
geod_xy("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
#>             x       y
#> [1,] 524492.1 5250246
#> [2,] 540886.1 5261273
```
