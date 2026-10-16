# Getting started with rgeodesy

``` r

library(rgeodesy)
```

rgeodesy wraps [Rust Geodesy](https://github.com/busstoptaktik/geodesy)
(RG), a platform for experiments with geodetic transformations. A
transformation is a **pipeline string** of named operators; you apply it
to vectors of coordinates.

## The core idea: pipelines, not CRS codes

Unlike PROJ, RG does not take EPSG codes or a `from -> to` pair of
coordinate reference systems. You spell out the transformation as a
pipeline of operator primitives chained with `|`, each taking
`key=value` arguments. For example, projecting geographic coordinates to
UTM zone 32:

``` r

geod_apply("gis:in | utm zone=32", x = 12, y = 55)
#> $x
#> [1] 691875.6
#> 
#> $y
#> [1] 6098908
```

## Coordinate order and units

RG works internally in radians with a geodetic (latitude-first) axis
order, so geographic data is bracketed with an I/O adaptor that converts
units and order:

- `gis:in` / `gis:out` — degrees in GIS order `(lon, lat)`, i.e. the
  natural `(x, y)` order. Recommended for most R users.
- `geo:in` / `geo:out` — degrees in geodetic order `(lat, lon)`.

These two give the same result when you swap the arguments:

``` r

geod_apply("gis:in | utm zone=55 south", x = 147.3, y = -42.9)
#> $x
#> [1] 524492.1
#> 
#> $y
#> [1] 5250246
geod_apply("geo:in | utm zone=55 south", x = -42.9, y = 147.3)
#> $x
#> [1] 524492.1
#> 
#> $y
#> [1] 5250246
```

## Inverse transformations

Pass `inv = TRUE` to run a pipeline backwards. Applying the forward
pipeline and then its inverse recovers the input:

``` r

fwd <- geod_apply("gis:in | utm zone=55 south", x = 147.3, y = -42.9)
fwd
#> $x
#> [1] 524492.1
#> 
#> $y
#> [1] 5250246
geod_apply("gis:in | utm zone=55 south", x = fwd$x, y = fwd$y, inv = TRUE)
#> $x
#> [1] 147.3
#> 
#> $y
#> [1] -42.9
```

## Matrix output

[`geod_xy()`](https://hypertidy.github.io/rgeodesy/reference/geod_xy.md)
returns a two-column matrix instead of a list, which is handy for
feeding into other spatial code:

``` r

geod_xy("gis:in | utm zone=55 south",
        x = c(147.3, 147.5),
        y = c(-42.9, -42.8))
#>             x       y
#> [1,] 524492.1 5250246
#> [2,] 540886.1 5261273
```

## Validating pipelines

[`geod_validate()`](https://hypertidy.github.io/rgeodesy/reference/geod_validate.md)
compiles a pipeline and returns `TRUE`, or an error string if it cannot
be built — useful for checking user input before applying it:

``` r

geod_validate("gis:in | utm zone=55 south")
#> [1] TRUE
geod_validate("utm zone=banana")
#> [1] "Malformed value for parameter 'zone': 'banana'"
```

A malformed pipeline passed to
[`geod_apply()`](https://hypertidy.github.io/rgeodesy/reference/geod_apply.md)
raises a normal R error:

``` r

geod_apply("utm zone=banana", x = 1, y = 1)
#> Error in `geod_apply()`:
#> ! Failed to build op 'utm zone=banana': Malformed value for parameter 'zone': 'banana'
```

## What’s available

[`geod_ops()`](https://hypertidy.github.io/rgeodesy/reference/geod_ops.md)
lists every registered operator and adaptor. See
[`vignette("operators")`](https://hypertidy.github.io/rgeodesy/articles/operators.md)
for a tour of the transformation families.

``` r

head(geod_ops(), 20)
#>  [1] "adapt"       "addone"      "axisswap"    "btmerc"      "butm"       
#>  [6] "cart"        "curvature"   "deflection"  "deformation" "dm"         
#> [11] "dms"         "enu:in"      "enu:out"     "geo:in"      "geo:out"    
#> [16] "geodesic"    "gis:in"      "gis:out"     "gravity"     "gridshift"
length(geod_ops())
#> [1] 44
```
