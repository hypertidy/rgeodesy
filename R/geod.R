#' rgeodesy: an R interface to Rust Geodesy
#'
#' rgeodesy exposes the [Rust Geodesy](https://github.com/busstoptaktik/geodesy)
#' (RG) library by Thomas Knudsen — a platform for experiments with geodetic
#' transformations and data flow. You build a transformation by writing a
#' *pipeline string* of named operators and apply it to vectors of coordinates.
#'
#' @section Specifying a transformation:
#' Rust Geodesy does not use EPSG codes or `"from" -> "to"` CRS pairs. Instead
#' you describe the transformation directly as a pipeline of operator
#' primitives, separated by `|`, each with `key=value` arguments:
#'
#' ```
#' gis:in | utm zone=32 | gis:out
#' ```
#'
#' Coordinates are handled in RG's internal convention (radians, geographic
#' latitude-first), so geographic input/output is wrapped with an adaptor:
#'
#' * `gis:in` / `gis:out` take degrees in the GIS order `(longitude, latitude)`
#'   — i.e. the natural `(x, y)` order, recommended for most R users.
#' * `geo:in` / `geo:out` take degrees in the geodetic order `(latitude, longitude)`.
#'
#' @section Operator families (Rust Geodesy 0.15):
#' * Projections: `utm`, `tmerc`, `btmerc`/`butm` (Bowring series),
#'   `merc`, `webmerc`, `lcc`, `laea`, `omerc`, `somerc`.
#' * Datum / reference-frame transforms: `cart`, `helmert`, `molodensky`,
#'   `gridshift`, `deformation`.
#' * Geodetic computations: `geodesic`, `curvature`, `gravity`, `latitude`,
#'   `deflection`, `permtide`.
#' * Adaptors and units: `adapt`, `axisswap`, `unitconvert`, `dm`, `dms`,
#'   the `geo:*` / `gis:*` / `neu:*` / `enu:*` I/O macros, and `noop`.
#'
#' Call [geod_ops()] for the full list and [geod_validate()] to check a
#' pipeline before using it. See the operator
#' [documentation](https://github.com/busstoptaktik/geodesy/blob/main/ruminations/002-rumination.md)
#' for arguments.
#'
#' @keywords internal
"_PACKAGE"

# Validate the common pipeline-string argument.
check_op_str <- function(op_str) {
  if (!is.character(op_str) || length(op_str) != 1L || is.na(op_str)) {
    stop("`op_str` must be a single, non-missing character string.", call. = FALSE)
  }
  invisible(op_str)
}

#' Apply a Rust Geodesy pipeline to coordinate vectors
#'
#' Compiles the pipeline once and applies it, vectorised, to all coordinate
#' pairs. Coordinates follow Rust Geodesy conventions: geographic data must be
#' bracketed with an adaptor operator (`gis:in`/`gis:out` for `(lon, lat)` in
#' degrees, or `geo:in`/`geo:out` for `(lat, lon)`), because RG works internally
#' in radians.
#'
#' @param op_str Character scalar. A Rust Geodesy pipeline string, e.g.
#'   `"gis:in | utm zone=32"`.
#' @param x Numeric vector. First coordinate (longitude/easting under the GIS
#'   convention).
#' @param y Numeric vector. Second coordinate (latitude/northing). Must be the
#'   same length as `x`.
#' @param inv Logical scalar. Run the inverse operation. Default `FALSE`.
#' @return A named list with numeric elements `x` and `y`, each the same length
#'   as the input.
#' @seealso [geod_xy()] for matrix output, [geod_validate()], [geod_ops()]
#' @family rgeodesy functions
#' @export
#' @examples
#' # Geographic (lon, lat) in degrees -> UTM zone 55 south (easting, northing)
#' geod_apply("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
#'
#' # Round trip: forward then inverse recovers the input
#' fwd <- geod_apply("gis:in | utm zone=55 south", x = 147.3, y = -42.9)
#' geod_apply("gis:in | utm zone=55 south", x = fwd$x, y = fwd$y, inv = TRUE)
#'
#' # Multi-step pipeline: geographic in, northing-easting-up out
#' geod_apply("gis:in | utm zone=32 | neu:out", x = c(12, 18), y = c(55, 59))
geod_apply <- function(op_str, x, y, inv = FALSE) {
  check_op_str(op_str)
  x <- as.double(x)
  y <- as.double(y)
  if (length(x) != length(y)) {
    stop(sprintf("`x` and `y` must have the same length (got %d and %d).",
                 length(x), length(y)), call. = FALSE)
  }
  .Call(wrap__geod_apply, op_str, x, y, isTRUE(inv))
}

#' Apply a pipeline and return a two-column matrix
#'
#' Convenience wrapper around [geod_apply()] that returns a numeric matrix with
#' columns `x` and `y` rather than a list.
#'
#' @inheritParams geod_apply
#' @return A numeric matrix with columns `x` and `y`, one row per input point.
#' @family rgeodesy functions
#' @export
#' @examples
#' geod_xy("gis:in | utm zone=55 south", x = c(147.3, 147.5), y = c(-42.9, -42.8))
geod_xy <- function(op_str, x, y, inv = FALSE) {
  r <- geod_apply(op_str, x, y, inv = inv)
  matrix(c(r$x, r$y), ncol = 2L, dimnames = list(NULL, c("x", "y")))
}

#' List available Rust Geodesy operators
#'
#' Returns the names of the built-in operators and coordinate adaptors
#' registered in a `Minimal` Rust Geodesy context. The list reflects the crate
#' version pinned by the package (Rust Geodesy 0.15).
#'
#' @return A sorted character vector of operator names.
#' @family rgeodesy functions
#' @export
#' @examples
#' ops <- geod_ops()
#' length(ops)
#' c("utm", "helmert", "laea") %in% ops
geod_ops <- function() {
  .Call(wrap__geod_ops)
}

#' Validate a Rust Geodesy pipeline string
#'
#' Attempts to compile the pipeline and returns `TRUE` if it succeeds, or a
#' character string describing the error if it fails. Useful for checking a
#' pipeline interactively before passing it to [geod_apply()].
#'
#' @param op_str Character scalar. A pipeline string to validate.
#' @return `TRUE` if valid, otherwise a character string with the error message.
#' @family rgeodesy functions
#' @export
#' @examples
#' geod_validate("gis:in | utm zone=55 south")  # TRUE
#' geod_validate("utm zone=banana")             # error string
geod_validate <- function(op_str) {
  check_op_str(op_str)
  .Call(wrap__geod_validate, op_str)
}
