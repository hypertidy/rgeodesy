# Validate a Rust Geodesy pipeline string

Attempts to compile the pipeline and returns `TRUE` if it succeeds, or a
character string describing the error if it fails. Useful for checking a
pipeline interactively before passing it to
[`geod_apply()`](https://hypertidy.github.io/rgeodesy/reference/geod_apply.md).

## Usage

``` r
geod_validate(op_str)
```

## Arguments

- op_str:

  Character scalar. A pipeline string to validate.

## Value

`TRUE` if valid, otherwise a character string with the error message.

## See also

Other rgeodesy functions:
[`geod_apply()`](https://hypertidy.github.io/rgeodesy/reference/geod_apply.md),
[`geod_ops()`](https://hypertidy.github.io/rgeodesy/reference/geod_ops.md),
[`geod_xy()`](https://hypertidy.github.io/rgeodesy/reference/geod_xy.md)

## Examples

``` r
geod_validate("gis:in | utm zone=55 south")  # TRUE
#> [1] TRUE
geod_validate("utm zone=banana")             # error string
#> [1] "Malformed value for parameter 'zone': 'banana'"
```
