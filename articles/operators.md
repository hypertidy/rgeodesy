# Operators and transformations

``` r

library(rgeodesy)
```

This article catalogues the transformation families that Rust Geodesy
(RG) 0.15 exposes through rgeodesy, and explains how a source-to-target
transformation is specified. The authoritative upstream reference is the
RG [operator
documentation](https://github.com/busstoptaktik/geodesy/blob/main/ruminations/002-rumination.md).

## How a transformation is specified

RG describes a transformation as a **pipeline** of operator primitives,
not as a pair of coordinate reference systems. There are no EPSG codes
in the core `Minimal` context used here; you compose the steps yourself:

- Chain operators with `|`.
- Give each operator `key=value` arguments (for example `utm zone=32`,
  `helmert x=-87 y=-96 z=-120`, `lcc lat_1=33 lat_2=45`).
- Choose the ellipsoid with `ellps=` (for example `ellps=GRS80`,
  `ellps=intl`); many operators default to GRS80.
- Reverse any single step with a trailing `inv`, or reverse the whole
  pipeline with `geod_apply(..., inv = TRUE)`.

``` r

geod_validate("gis:in | utm zone=32 | gis:out")
#> [1] TRUE
```

The full set of registered names:

``` r

geod_ops()
#>  [1] "adapt"       "addone"      "axisswap"    "btmerc"      "butm"       
#>  [6] "cart"        "curvature"   "deflection"  "deformation" "dm"         
#> [11] "dms"         "enu:in"      "enu:out"     "geo:in"      "geo:out"    
#> [16] "geodesic"    "gis:in"      "gis:out"     "gravity"     "gridshift"  
#> [21] "helmert"     "laea"        "latitude"    "latlon"      "latlong"    
#> [26] "lcc"         "longlat"     "lonlat"      "merc"        "molodensky" 
#> [31] "neu:in"      "neu:out"     "noop"        "omerc"       "permtide"   
#> [36] "pipeline"    "pop"         "push"        "somerc"      "stack"      
#> [41] "tmerc"       "unitconvert" "utm"         "webmerc"
```

## Projections

RG supports a focused set of high-quality projections. Geographic input
is bracketed with `gis:in` (and `gis:out` for geographic output).

| Operator | Projection | Notes |
|----|----|----|
| `utm` | Universal Transverse Mercator | `zone=`, optional `south` |
| `tmerc` | Transverse Mercator | `lon_0=`, `lat_0=`, `k_0=` |
| `btmerc` / `butm` | Bowring series transverse Mercator / its UTM form | wider accurate zone |
| `merc` | Mercator |  |
| `webmerc` | Web (pseudo) Mercator | spherical development |
| `lcc` | Lambert Conformal Conic | one or two standard parallels |
| `laea` | Lambert Azimuthal Equal Area | `lat_0=`, `lon_0=` |
| `omerc` | Oblique Mercator |  |
| `somerc` | Swiss Oblique Mercator |  |

``` r

# A few projections for Copenhagen (12 E, 55 N)
projections <- c(
  "utm zone=32",
  "merc",
  "webmerc",
  "lcc lat_0=52 lat_1=33 lat_2=45",
  "laea lat_0=52 lon_0=10"
)
t(vapply(projections, function(p) {
  r <- geod_apply(paste("gis:in |", p), x = 12, y = 55)
  c(x = r$x, y = r$y)
}, numeric(2)))
#>                                        x         y
#> utm zone=32                     691875.6 6098907.8
#> merc                           1335833.9 7326837.7
#> webmerc                        1335833.9 7361866.1
#> lcc lat_0=52 lat_1=33 lat_2=45  794682.6  396334.1
#> laea lat_0=52 lon_0=10          128020.4  335613.6
```

## Datum and reference-frame transforms

These operators move coordinates between datums or reference frames.

| Operator | Transform |
|----|----|
| `cart` | geographic \<-\> geocentric cartesian (XYZ) |
| `helmert` | Helmert / similarity transform (3-, 6-, 7- or 14-parameter, including time-dependent frames) |
| `molodensky` | abridged and full Molodensky |
| `gridshift` | grid-based datum shift (needs a `grids=` resource) |
| `deformation` | kinematic shift using a 3-D deformation model |

A classic datum shift is built by going to cartesian space, applying a
Helmert transform, and coming back:

``` r

geod_validate("geo:in | cart | helmert x=-87 y=-96 z=-120 | cart inv ellps=intl | geo:out")
#> [1] TRUE
```

**A 2-D caveat.** rgeodesy currently passes two coordinates per point
(`x`, `y`). `cart`, `helmert` and `deformation` are intrinsically
three-dimensional and need a height to round-trip faithfully, so these
datum transforms are not yet fully usable through the 2-D interface.
Projections and 2-D operators are unaffected.

## Geodetic computations

Beyond coordinate operations, RG registers operators for geodetic
quantities:

| Operator | Computes |
|----|----|
| `geodesic` | geodesic distance and azimuth (direct / inverse problems) |
| `curvature` | radii of curvature (prime vertical, meridian, Gaussian, mean) |
| `gravity` | normal gravity |
| `latitude` | auxiliary latitudes (authalic, conformal, geocentric, rectifying, …) |
| `deflection` | deflection of the vertical from a geoid model |
| `permtide` | conversion between permanent-tide systems |

Most of these require a flag naming the quantity, for example:

``` r

geod_validate("curvature meridian")
#> [1] TRUE
geod_validate("latitude authalic")
#> [1] TRUE
```

## Adaptors, units and control

| Operator | Role |
|----|----|
| `adapt` | declarative coordinate order / unit adaptor |
| `axisswap` | imperative axis-order swap |
| `unitconvert` | angular and linear unit conversion |
| `dm`, `dms` | degree-minute and degree-minute-second encodings |
| `geo:*`, `gis:*`, `neu:*`, `enu:*` | built-in I/O macros (see below) |
| `noop` (and aliases `longlat`, `latlon`, `latlong`, `lonlat`) | pass-through |
| `push`, `pop`, `stack` | coordinate-dimension stack handlers |

The I/O macros are thin wrappers over `adapt`:

| Macro                | Units   | Axis order              |
|----------------------|---------|-------------------------|
| `gis:in` / `gis:out` | degrees | east-north `(lon, lat)` |
| `geo:in` / `geo:out` | degrees | north-east `(lat, lon)` |
| `enu:in` / `enu:out` | radians | east-north              |
| `neu:in` / `neu:out` | radians | north-east              |

## A note on the `pipeline` operator

RG builds pipelines from the `|` separator; there is no need to name a
`pipeline` operator yourself. Compiling a bare `pipeline` recurses
without bound upstream and would crash the R session, so rgeodesy
refuses it with a clear message:

``` r

geod_validate("pipeline")
#> [1] "the bare 'pipeline' operator is not supported: it recurses infinitely in Rust Geodesy and would crash R. Compose steps with the '|' separator instead, e.g. 'geo:in | utm zone=32'."
```
