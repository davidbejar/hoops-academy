//! Hexagonal layering, the counterpart of `ArchUnit` (ADR-0051 §4, ADR-0052): each layer is a crate, so code can only
//! use the crates its manifest lists and a wrong import does not compile. This test pins those lists: the domain uses
//! no framework (no HTTP, serde, async runtime, PDF engine or logging crate) and depends on no other layer; the
//! application depends on the domain only; nothing depends on the adapters.
#![allow(clippy::unwrap_used, clippy::expect_used)] // a test fails loudly

use std::collections::BTreeSet;

fn dependencies(krate: &str, table: &str) -> BTreeSet<String> {
    let path = format!("{}/../{krate}/Cargo.toml", env!("CARGO_MANIFEST_DIR"));
    let manifest: toml::Table = std::fs::read_to_string(path).unwrap().parse().unwrap();
    manifest.get(table).and_then(toml::Value::as_table).map(|deps| deps.keys().cloned().collect()).unwrap_or_default()
}

fn set(names: &[&str]) -> BTreeSet<String> {
    names.iter().map(|n| (*n).to_owned()).collect()
}

#[test]
fn the_domain_uses_no_framework_and_no_other_layer() {
    assert_eq!(dependencies("domain", "dependencies"), set(&["chrono", "chrono-tz", "unicode-normalization"]));
    assert!(dependencies("domain", "dev-dependencies").is_empty());
}

#[test]
fn the_application_depends_on_the_domain_only() {
    assert_eq!(dependencies("application", "dependencies"), set(&["chrono", "pdf-domain"]));
    assert_eq!(dependencies("application", "dev-dependencies"), set(&["chrono-tz"]));
}

#[test]
fn nothing_depends_on_the_adapters() {
    for krate in ["domain", "application"] {
        for table in ["dependencies", "dev-dependencies", "build-dependencies"] {
            assert!(!dependencies(krate, table).contains("pdf-adapters"), "{krate} {table}");
        }
    }
    let adapters = dependencies("adapters", "dependencies");
    assert!(adapters.contains("pdf-domain") && adapters.contains("pdf-application"));
}

#[test]
fn the_workspace_has_exactly_the_three_layers() {
    let path = format!("{}/../../Cargo.toml", env!("CARGO_MANIFEST_DIR"));
    let manifest: toml::Table = std::fs::read_to_string(path).unwrap().parse().unwrap();
    let members: Vec<&str> =
        manifest["workspace"]["members"].as_array().unwrap().iter().map(|m| m.as_str().unwrap()).collect();
    assert_eq!(members, ["crates/domain", "crates/application", "crates/adapters"]);
}
