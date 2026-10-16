# List available Rust Geodesy operators

Returns the names of the built-in operators and coordinate adaptors
registered in a `Minimal` Rust Geodesy context. The list reflects the
crate version pinned by the package (Rust Geodesy 0.15).

## Usage

``` r
geod_ops()
```

## Value

A sorted character vector of operator names.

## See also

Other rgeodesy functions:
[`geod_apply()`](https://hypertidy.github.io/rgeodesy/reference/geod_apply.md),
[`geod_validate()`](https://hypertidy.github.io/rgeodesy/reference/geod_validate.md),
[`geod_xy()`](https://hypertidy.github.io/rgeodesy/reference/geod_xy.md)

## Examples

``` r
ops <- geod_ops()
length(ops)
#> [1] 44
c("utm", "helmert", "laea") %in% ops
#> [1] TRUE TRUE TRUE
```
