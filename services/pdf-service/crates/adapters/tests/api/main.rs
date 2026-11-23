//! One integration binary for the tests that share the service set-up (one RSA key, one link of the adapters crate):
//! the HTTP API, the contract, the renderer, the realm verifier and the layering. `logs.rs` stays its own binary:
//! tracing caches callsite interest per process.
#![allow(clippy::unwrap_used, clippy::expect_used)] // a test fails loudly

#[path = "../common/mod.rs"]
mod common;

mod contract;
mod http;
mod layering;
mod realm;
mod render;
