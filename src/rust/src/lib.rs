#![allow(non_snake_case)]

use extendr_api::prelude::*;
use geodesy::prelude::*;

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Reject operator strings that are known to recurse infinitely in Rust
/// Geodesy and take down the R session with a C stack overflow.
///
/// The bare `pipeline` operator is the main offender: `Minimal::op("pipeline")`
/// recurses without bound (a stack overflow is a hardware fault, not a Rust
/// panic, so it cannot be caught with `catch_unwind`). We therefore refuse it
/// up front. Real pipelines are built with the `|` separator, e.g.
/// `"geo:in | utm zone=32"`, and do not hit this path.
fn guard_recursive(op_str: &str) -> std::result::Result<(), String> {
    for step in op_str.split('|') {
        let name = step.trim().split_whitespace().next().unwrap_or("");
        if name == "pipeline" {
            return Err(
                "the bare 'pipeline' operator is not supported: it recurses \
                 infinitely in Rust Geodesy and would crash R. Compose steps \
                 with the '|' separator instead, e.g. 'geo:in | utm zone=32'."
                    .to_string(),
            );
        }
    }
    Ok(())
}

/// Build a Minimal context, compile an op string, apply to (x, y) vectors,
/// return (x, y) as numeric vectors. Used by the public R wrappers.
///
/// The whole compile+apply is wrapped in `catch_unwind` so that a panic inside
/// Rust Geodesy surfaces as a clean R error rather than aborting the session.
fn apply_op(
    op_str: &str,
    x: &[f64],
    y: &[f64],
    inv: bool,
) -> std::result::Result<(Vec<f64>, Vec<f64>), String> {
    if x.len() != y.len() {
        return Err(format!(
            "x and y must have the same length (got {} and {})",
            x.len(),
            y.len()
        ));
    }
    guard_recursive(op_str)?;

    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(
        || -> std::result::Result<(Vec<f64>, Vec<f64>), String> {
            let mut ctx = Minimal::new();
            let op = ctx
                .op(op_str)
                .map_err(|e| format!("Failed to build op '{}': {}", op_str, e))?;

            // Coordinates are taken as-is. Geographic input must be handled with
            // a `geo:in` / `gis:in` adaptor in the pipeline (RG works internally
            // in radians); `geo:out` / `gis:out` convert back to degrees.
            let mut data: Vec<Coor2D> = x
                .iter()
                .zip(y.iter())
                .map(|(&xi, &yi)| Coor2D([xi, yi]))
                .collect();

            let dir = if inv { Inv } else { Fwd };
            ctx.apply(op, dir, &mut data)
                .map_err(|e| format!("Failed to apply op '{}': {}", op_str, e))?;

            let out_x: Vec<f64> = data.iter().map(|c| c[0]).collect();
            let out_y: Vec<f64> = data.iter().map(|c| c[1]).collect();
            Ok((out_x, out_y))
        },
    ));

    match result {
        Ok(inner) => inner,
        Err(_) => Err(format!(
            "Rust Geodesy panicked while building or applying '{}'",
            op_str
        )),
    }
}

// ── Exported functions ────────────────────────────────────────────────────────

/// Apply a Rust Geodesy pipeline to coordinate vectors.
///
/// Compiles the pipeline string once and applies it to all coordinate pairs in
/// a single batch. Raises an R error if the pipeline fails to compile or apply.
///
/// @param op_str Character scalar. A Rust Geodesy pipeline string,
///   e.g. `"utm zone=32"` or `"geo:in | utm zone=55 | neu:out"`.
/// @param x Numeric vector. First coordinate.
/// @param y Numeric vector. Second coordinate. Must be the same length as `x`.
/// @param inv Logical scalar. Run the inverse operation. Default `FALSE`.
/// @return A list with elements `x` and `y`, each a numeric vector of the
///   same length as the input.
#[extendr]
fn geod_apply(op_str: &str, x: &[f64], y: &[f64], inv: bool) -> Robj {
    match apply_op(op_str, x, y, inv) {
        Ok((out_x, out_y)) => list!(x = out_x, y = out_y).into(),
        // `throw_r_error` diverges via `Rf_error`, giving a clean R error with
        // our message instead of extendr's generic "User function panicked".
        Err(e) => extendr_api::throw_r_error(e),
    }
}

/// List the operators available in a Minimal Rust Geodesy context.
///
/// Returns the names of all built-in operators and coordinate adaptors
/// registered in a freshly created `Minimal` context. The list mirrors the
/// `BUILTIN_OPERATORS` and `BUILTIN_ADAPTORS` tables of Rust Geodesy 0.15 and
/// must be kept in step with the pinned crate version.
///
/// @return A sorted character vector of operator names.
#[extendr]
fn geod_ops() -> Vec<String> {
    // Mirrors geodesy 0.15 src/inner_op/mod.rs (BUILTIN_OPERATORS) and
    // src/context/mod.rs (BUILTIN_ADAPTORS). `addone` is an upstream demo op.
    let mut ops = vec![
        // projections
        "utm", "tmerc", "btmerc", "butm", "merc", "webmerc", "lcc", "laea",
        "omerc", "somerc",
        // datum / reference-frame transforms
        "cart", "helmert", "molodensky", "gridshift", "deformation",
        // geodetic utilities
        "geodesic", "curvature", "gravity", "latitude", "deflection", "permtide",
        // coordinate adaptors and unit handling
        "adapt", "axisswap", "unitconvert", "dm", "dms",
        // pipeline / stack handlers
        "pipeline", "push", "pop", "stack",
        // noop and its aliases
        "noop", "longlat", "latlon", "latlong", "lonlat",
        // demo operator
        "addone",
        // built-in I/O adaptor macros
        "geo:in", "geo:out", "gis:in", "gis:out", "neu:in", "neu:out", "enu:in",
        "enu:out",
    ];
    ops.sort();
    ops.iter().map(|s| s.to_string()).collect()
}

/// Validate a Rust Geodesy pipeline string.
///
/// Attempts to compile the pipeline and returns `TRUE` if it succeeds, or a
/// character string describing the error if it fails.
///
/// @param op_str Character scalar. A Rust Geodesy pipeline string.
/// @return `TRUE` if the pipeline is valid, or a character string with the
///   error message.
#[extendr]
fn geod_validate(op_str: &str) -> Robj {
    if let Err(e) = guard_recursive(op_str) {
        return r!(e);
    }
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        let mut ctx = Minimal::new();
        match ctx.op(op_str) {
            Ok(_) => Ok(()),
            Err(e) => Err(format!("{}", e)),
        }
    }));
    match result {
        Ok(Ok(())) => r!(TRUE),
        Ok(Err(e)) => r!(e),
        Err(_) => r!(format!("Rust Geodesy panicked while compiling '{}'", op_str)),
    }
}

extendr_module! {
    mod rgeodesy;
    fn geod_apply;
    fn geod_ops;
    fn geod_validate;
}
