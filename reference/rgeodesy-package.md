# rgeodesy: an R interface to Rust Geodesy

rgeodesy exposes the [Rust
Geodesy](https://github.com/busstoptaktik/geodesy) (RG) library by
Thomas Knudsen — a platform for experiments with geodetic
transformations and data flow. You build a transformation by writing a
*pipeline string* of named operators and apply it to vectors of
coordinates.

## Specifying a transformation

Rust Geodesy does not use EPSG codes or `"from" -> "to"` CRS pairs.
Instead you describe the transformation directly as a pipeline of
operator primitives, separated by `|`, each with `key=value` arguments:

    gis:in | utm zone=32 | gis:out

Coordinates are handled in RG's internal convention (radians, geographic
latitude-first), so geographic input/output is wrapped with an adaptor:

- `gis:in` / `gis:out` take degrees in the GIS order
  `(longitude, latitude)` — i.e. the natural `(x, y)` order, recommended
  for most R users.

- `geo:in` / `geo:out` take degrees in the geodetic order
  `(latitude, longitude)`.

## Operator families (Rust Geodesy 0.15)

- Projections: `utm`, `tmerc`, `btmerc`/`butm` (Bowring series), `merc`,
  `webmerc`, `lcc`, `laea`, `omerc`, `somerc`.

- Datum / reference-frame transforms: `cart`, `helmert`, `molodensky`,
  `gridshift`, `deformation`.

- Geodetic computations: `geodesic`, `curvature`, `gravity`, `latitude`,
  `deflection`, `permtide`.

- Adaptors and units: `adapt`, `axisswap`, `unitconvert`, `dm`, `dms`,
  the `geo:*` / `gis:*` / `neu:*` / `enu:*` I/O macros, and `noop`.

Call
[`geod_ops()`](https://hypertidy.github.io/rgeodesy/reference/geod_ops.md)
for the full list and
[`geod_validate()`](https://hypertidy.github.io/rgeodesy/reference/geod_validate.md)
to check a pipeline before using it. See the operator
[documentation](https://github.com/busstoptaktik/geodesy/blob/main/ruminations/002-rumination.md)
for arguments.

## See also

Useful links:

- <https://github.com/hypertidy/rgeodesy>

- <https://hypertidy.github.io/rgeodesy/>

- Report bugs at <https://github.com/hypertidy/rgeodesy/issues>

## Author

**Maintainer**: Michael Sumner <mdsumner@gmail.com>
([ORCID](https://orcid.org/0000-0002-2471-7511))

Authors:

- Michael Sumner <mdsumner@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-2471-7511))
