//! Adapters of pdf-service (ADR-0052): the HTTP API in (axum), bearer tokens, Problem+JSON, security events, the
//! krilla renderer out, the system clock, configuration and telemetry. `main.rs` wires them.

pub mod auth;
pub mod config;
pub mod dto;
pub mod http;
pub mod problem;
pub mod render;
pub mod security;
pub mod telemetry;

use chrono::{DateTime, Utc};
use pdf_application::Clock;

/// The wall clock (driven adapter of [`Clock`]).
#[derive(Debug, Clone, Copy, Default)]
pub struct SystemClock;

impl Clock for SystemClock {
    fn now(&self) -> DateTime<Utc> {
        Utc::now()
    }
}
