//! `libs/contracts/openapi/pdf.yaml` (and the `Problem` of `common.yaml`) as JSON Schemas, to validate the requests
//! the tests send and the answers the service gives. `OpenAPI` 3.0 schemas are JSON Schema plus `nullable`, which is
//! rewritten to a `null` type (or a `null` enum value) before validation.

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

use serde_json::{Map, Value, json};

fn contracts_dir() -> String {
    format!("{}/../../../../libs/contracts/openapi", env!("CARGO_MANIFEST_DIR"))
}

/// A contract file, read and parsed once per test binary.
pub fn document(name: &str) -> &'static Value {
    static DOCUMENTS: OnceLock<Mutex<HashMap<String, &'static Value>>> = OnceLock::new();
    let mut documents = DOCUMENTS.get_or_init(Mutex::default).lock().expect("the cache");
    documents.entry(name.to_owned()).or_insert_with(|| {
        let text = std::fs::read_to_string(format!("{}/{name}", contracts_dir())).expect("contract file");
        Box::leak(Box::new(serde_norway::from_str(&text).expect("contract YAML")))
    })
}

pub fn yaml(name: &str) -> Value {
    document(name).clone()
}

/// `nullable: true` -> `type: [t, "null"]` (and `null` among an `enum`), everywhere below `schema`.
fn json_schema(schema: &Value) -> Value {
    match schema {
        Value::Object(map) => {
            let mut out: Map<String, Value> =
                map.iter().filter(|(k, _)| *k != "nullable").map(|(k, v)| (k.clone(), json_schema(v))).collect();
            if map.get("nullable") == Some(&Value::Bool(true)) {
                if let Some(Value::String(kind)) = out.get("type").cloned() {
                    out.insert("type".into(), json!([kind, "null"]));
                }
                if let Some(Value::Array(values)) = out.get_mut("enum") {
                    values.push(Value::Null);
                }
            }
            Value::Object(out)
        }
        Value::Array(items) => Value::Array(items.iter().map(json_schema).collect()),
        other => other.clone(),
    }
}

/// The validator for `#/components/schemas/<name>` of `file`, compiled once per test binary.
pub fn validator(file: &str, name: &str) -> &'static jsonschema::Validator {
    static VALIDATORS: OnceLock<Mutex<HashMap<(String, String), &'static jsonschema::Validator>>> = OnceLock::new();
    let mut validators = VALIDATORS.get_or_init(Mutex::default).lock().expect("the cache");
    validators.entry((file.to_owned(), name.to_owned())).or_insert_with(|| Box::leak(Box::new(compile(file, name))))
}

fn compile(file: &str, name: &str) -> jsonschema::Validator {
    let components = json_schema(&document(file)["components"]);
    let root = json!({
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$ref": format!("#/components/schemas/{name}"),
        "components": components,
    });
    jsonschema::draft202012::options().should_validate_formats(true).build(&root).expect("a valid schema")
}

/// The errors of `instance` against `#/components/schemas/<name>` of `file` (empty: valid).
pub fn errors(file: &str, name: &str, instance: &Value) -> Vec<String> {
    validator(file, name).iter_errors(instance).map(|e| format!("{} at {}", e, e.instance_path())).collect()
}

/// The operation of `pdf.yaml` at `path` (POST).
pub fn operation(path: &str) -> Value {
    document("pdf.yaml")["paths"][path]["post"].clone()
}

/// The response the contract declares for `status` of the operation at `path`, resolved.
pub fn declared_response(path: &str, status: u16) -> Option<Value> {
    let response = operation(path)["responses"][status.to_string()].clone();
    let reference = response.get("$ref")?.as_str()?.rsplit('/').next()?.to_owned();
    Some(document("pdf.yaml")["components"]["responses"][reference].clone())
}
