#![allow(non_snake_case)]

use extendr_api::prelude::*;
use geodesy::prelude::*;

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Build a Minimal context, compile an op string, apply to (x, y) vectors,
/// return a list(x = numeric, y = numeric). Used by the public R wrappers.
fn apply_op(
    op_str: &str,
    x: &[f64],
    y: &[f64],
    inv: bool,
) -> std::result::Result<(Vec<f64>, Vec<f64>), String> {
    if x.len() != y.len() {
        return Err(format!(
            "x and y must have the same length (got {} and {})",
            x.len(), y.len()
        ));
    }

    let mut ctx = Minimal::new();
    let op = ctx
        .op(op_str)
        .map_err(|e| format!("Failed to build op '{}': {}", op_str, e))?;

    // RG works internally in radians. Convert degree inputs if the pipeline
    // does not include a geo:in adaptor. We always wrap with geo:in | ... | geo:out
    // at the Rust level so the R user works in degrees throughout.
    // Actually we leave this to the user via the pipeline string — raw Coor2D
    // takes values as-is. The canonical pipeline for geographic->projected is
    // "geo:in | utm zone=N" and for the inverse "utm zone=N | geo:out".
    let mut data: Vec<Coor2D> = x
        .iter()
        .zip(y.iter())
        .map(|(&xi, &yi)| Coor2D([xi, yi]))
        .collect();

    let dir = if inv { Inv } else { Fwd };
    ctx.apply(op, dir, &mut data)
        .map_err(|e| format!("Failed to apply op: {}", e))?;

    let out_x: Vec<f64> = data.iter().map(|c| c[0]).collect();
    let out_y: Vec<f64> = data.iter().map(|c| c[1]).collect();

    Ok((out_x, out_y))
}

// ── Exported functions ────────────────────────────────────────────────────────

/// Apply a Rust Geodesy pipeline to coordinate vectors.
///
/// Compiles the pipeline string once and applies it to all coordinate pairs in
/// a single batch. The pipeline syntax follows Rust Geodesy (RG), which is
/// similar to PROJ pipelines but not identical. See
/// <https://github.com/busstoptaktik/geodesy/blob/main/ruminations/002-rumination.md>
/// for operator documentation.
///
/// Input coordinates should be in the *natural* order for the operator — for
/// geographic operations this is (longitude, latitude) in decimal degrees, for
/// projected operations it is (easting, northing) in metres.
///
/// @param op_str Character scalar. A Rust Geodesy pipeline string,
///   e.g. `"utm zone=32"` or `"geo:in | utm zone=55 | neu:out"`.
/// @param x Numeric vector. First coordinate (longitude or easting).
/// @param y Numeric vector. Second coordinate (latitude or northing).
///   Must be the same length as `x`.
/// @param inv Logical scalar. Run the inverse operation. Default `FALSE`.
/// @return A list with elements `x` and `y`, each a numeric vector of the
///   same length as the input.
/// @export
/// @examples
/// \dontrun{
/// # UTM zone 55 (Tasmania)
/// geod_apply("utm zone=55", x = c(147.3, 147.5), y = c(-42.9, -42.8))
///
/// # Inverse: UTM -> geographic
/// geod_apply("utm zone=55", x = c(509576, 527060), y = c(5247523, 5258991),
///            inv = TRUE)
///
/// # Pipeline: geographic in, northing-easting-up out
/// geod_apply("geo:in | utm zone=32 | neu:out",
///            x = c(12., 18.), y = c(55., 59.))
/// }
#[extendr]
fn geod_apply(op_str: &str, x: &[f64], y: &[f64], inv: bool) -> Robj {
    match apply_op(op_str, x, y, inv) {
        Ok((out_x, out_y)) => list!(x = out_x, y = out_y).into(),
        Err(e) => {
            rprintln!("Error in geod_apply: {}", e);
            r!(NULL)
        }
    }
}

/// List the operators available in a Minimal Rust Geodesy context.
///
/// Returns the names of all built-in operators registered in a freshly
/// created `Minimal` context. Useful for discovery — to see what pipelines
/// you can build.
///
/// @return A character vector of operator names.
/// @export
/// @examples
/// ops <- geod_ops()
/// head(ops)
/// "utm" %in% ops
#[extendr]
fn geod_ops() -> Vec<String> {
    // Operators available in a Minimal context as of geodesy 0.15.
    // From https://github.com/busstoptaktik/geodesy/blob/main/ruminations/002-rumination.md
    let mut ops = vec![
        "adapt", "affine", "axisswap", "cart", "deformation",
        "dm", "geoid", "gridshift", "helmert", "hgridshift",
        "horner", "latshift", "lcc", "laea", "merc",
        "molodensky", "namepipes", "noop", "normalize", "omerc",
        "pipeline", "pop", "proj", "push", "tmerc",
        "unitconvert", "utm", "vgridshift", "webmerc",
        // adaptor ops
        "geo:in", "geo:out", "gis:in", "gis:out",
        "neu:in", "neu:out", "enu:in", "enu:out",
    ];
    ops.sort();
    ops.iter().map(|s| s.to_string()).collect()
}

/// Validate a Rust Geodesy pipeline string.
///
/// Attempts to compile the pipeline and returns `TRUE` if it succeeds,
/// or a character string describing the error if it fails. Useful for
/// checking pipelines interactively before passing to [geod_apply()].
///
/// @param op_str Character scalar. A Rust Geodesy pipeline string.
/// @return `TRUE` if the pipeline is valid, or a character string with
///   the error message.
/// @export
/// @examples
/// geod_validate("utm zone=32")        # TRUE
/// geod_validate("utm zone=banana")    # error string
/// geod_validate("geo:in | utm zone=55 | neu:out")  # TRUE
#[extendr]
fn geod_validate(op_str: &str) -> Robj {
    let mut ctx = Minimal::new();
    match ctx.op(op_str) {
        Ok(_) => r!(TRUE),
        Err(e) => r!(format!("{}", e)),
    }
}

extendr_module! {
    mod rgeodesy;
    fn geod_apply;
    fn geod_ops;
    fn geod_validate;
}
