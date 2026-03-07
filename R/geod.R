#' Apply a Rust Geodesy pipeline to coordinate vectors
#'
#' Compiles the pipeline once and applies it vectorised to all coordinate
#' pairs. Coordinates and units follow Rust Geodesy conventions directly —
#' RG works internally in radians, and geographic coordinates require the
#' `geo:in` / `geo:out` adaptor operators to convert from/to degrees. Axis
#' order follows RG conventions (latitude first for geographic operations
#' unless `axisswap` is used).
#'
#' See the [operator documentation](https://github.com/busstoptaktik/geodesy/blob/main/ruminations/002-rumination.md)
#' for pipeline syntax and available operators.
#'
#' @param op_str Character scalar. A Rust Geodesy pipeline string,
#'   e.g. `"geo:in | utm zone=55 south"`.
#' @param x Numeric vector. First coordinate.
#' @param y Numeric vector. Second coordinate. Must be the same length as `x`.
#' @param inv Logical. Run the inverse operation. Default `FALSE`.
#' @return A named list with elements `x` and `y`.
#' @export
#' @seealso [geod_xy()] for matrix output, [geod_validate()], [geod_ops()]
#' @examples
#' \dontrun{
#' # geo:in converts degrees to radians and sets (lat, lon) internal order
#' geod_apply("geo:in | utm zone=55 south", x = c(-42.9, -42.8), y = c(147.3, 147.5))
#'
#' # inverse
#' geod_apply("utm zone=55 south | geo:out", x = c(500000, 510000), y = c(5248000, 5260000))
#' }
geod_apply <- function(op_str, x, y, inv = FALSE) {
  .Call(wrap__geod_apply, op_str, as.double(x), as.double(y), isTRUE(inv))
}

#' Apply a pipeline and return a two-column matrix
#'
#' Convenience wrapper around [geod_apply()] that returns a numeric matrix
#' with columns `x` and `y` rather than a list.
#'
#' @inheritParams geod_apply
#' @return A numeric matrix with columns `x` and `y`, one row per input point.
#' @export
#' @examples
#' \dontrun{
#' geod_xy("geo:in | utm zone=55 south", x = c(-42.9, -42.8), y = c(147.3, 147.5))
#' }
geod_xy <- function(op_str, x, y, inv = FALSE) {
  r <- geod_apply(op_str, x, y, inv = inv)
  matrix(c(r$x, r$y), ncol = 2L, dimnames = list(NULL, c("x", "y")))
}

#' List available Rust Geodesy operators
#'
#' Returns the names of built-in operators available in a `Minimal` context.
#'
#' @return A sorted character vector of operator names.
#' @export
#' @examples
#' ops <- geod_ops()
#' "utm" %in% ops
#' "helmert" %in% ops
geod_ops <- function() {
  .Call(wrap__geod_ops)
}

#' Validate a Rust Geodesy pipeline string
#'
#' Attempts to compile the pipeline and returns `TRUE` if it succeeds,
#' or a character string describing the error if it fails.
#'
#' @param op_str Character scalar. A pipeline string to validate.
#' @return `TRUE` if valid, or a character string with the error message.
#' @export
#' @examples
#' geod_validate("geo:in | utm zone=55 south")
#' geod_validate("utm zone=banana")
geod_validate <- function(op_str) {
  .Call(wrap__geod_validate, op_str)
}
