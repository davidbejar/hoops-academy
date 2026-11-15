//! Nothing of a request body reaches a log line or a span (ADR-0046, P-11); the security event is written with its
//! fields (ADR-0043). Its own test binary: tracing caches callsite interest per process, and a scoped subscriber in a
//! binary whose other tests run in parallel without one would miss events.
#![allow(clippy::unwrap_used, clippy::expect_used)] // a test fails loudly

mod common;

use std::io::Write;
use std::sync::{Arc, Mutex};

use axum::http::{Method, StatusCode};
use common::app::{call, core_token, fixture, post, service, token, web_claims};
use serde_json::json;

/// Captures everything the service writes through tracing (events and closed spans with their fields).
#[derive(Clone, Default)]
struct Captured(Arc<Mutex<Vec<u8>>>);

impl Write for Captured {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        self.0.lock().unwrap().extend_from_slice(buf);
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

impl<'a> tracing_subscriber::fmt::MakeWriter<'a> for Captured {
    type Writer = Captured;

    fn make_writer(&'a self) -> Self::Writer {
        self.clone()
    }
}

#[tokio::test]
async fn nothing_of_the_body_reaches_a_log_line_or_a_span() {
    let captured = Captured::default();
    let subscriber = tracing_subscriber::fmt()
        .json()
        .with_writer(captured.clone())
        .with_max_level(tracing::Level::TRACE)
        .with_span_events(tracing_subscriber::fmt::format::FmtSpan::CLOSE)
        .with_current_span(true)
        .with_span_list(true)
        .finish();
    let _guard = tracing::subscriber::set_default(subscriber);
    let service = service();
    let ok = post(&service.router, "/internal/pdf/team-roster", &fixture("team-roster.json")).await;
    assert_eq!(ok.status, StatusCode::OK);
    let mut bad = fixture("team-roster.json");
    bad["players"][0]["jerseyNumber"] = json!("Sari Wijaya");
    let refused = post(&service.router, "/internal/pdf/team-roster", &bad).await;
    assert_eq!(refused.status, StatusCode::BAD_REQUEST);
    let web = format!("Bearer {}", token(&web_claims()));
    let headers = [("authorization", web.as_str()), ("content-type", "application/json")];
    let body = serde_json::to_vec(&fixture("match-sheet.json")).unwrap();
    let denied = call(&service.router, Method::POST, "/internal/pdf/match-sheet", &headers, body).await;
    assert_eq!(denied.status, StatusCode::UNAUTHORIZED);

    let log = String::from_utf8(captured.0.lock().unwrap().clone()).unwrap();
    assert!(log.contains("\"http.route\":\"/internal/pdf/team-roster\""), "the request span is written: {log}");
    assert!(
        log.contains("\"security.kind\":\"invalid_token\"") && log.contains("\"security.reason\":\"audience\""),
        "{log}"
    );
    assert!(log.contains("hoops.security"), "{log}");
    assert_no_request_values(log.as_bytes());
    assert!(!log.contains(&core_token()[..20]), "no token in the log");
}

fn assert_no_request_values(bytes: &[u8]) {
    let text = String::from_utf8_lossy(bytes);
    for value in ["Sari", "Wijaya", "Agus", "Lestari", "agus@example.test", "+62 81", "Lucía", "Martínez", "Garuda"] {
        assert!(!text.contains(value), "{value:?} leaked into the log");
    }
}
