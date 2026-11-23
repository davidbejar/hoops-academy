//! The verifier against a realm over HTTP (a local stand-in for Keycloak's discovery document and JWKS): the issuer
//! comes from discovery, the keys are read once and again only for an unknown key id, and an unreachable realm is a
//! 503 `AUTH_UNAVAILABLE`, never a 401.

use crate::common;

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};

use axum::Router;
use axum::http::{HeaderValue, StatusCode};
use axum::routing::get;
use common::app::{ISSUER, core_service_claims, core_token, post_raw, realm_key, token_with};
use pdf_adapters::SystemClock;
use pdf_adapters::auth::{AuthFailure, TokenVerifier};
use pdf_adapters::config::Config;
use pdf_adapters::http::{AppState, router};
use pdf_adapters::render::KrillaRenderer;
use pdf_adapters::security::SecurityEvents;
use pdf_application::PrintSheets;
use serde_json::json;

struct Realm {
    url: String,
    discovery: Arc<AtomicUsize>,
    certs: Arc<AtomicUsize>,
}

async fn realm() -> Realm {
    let discovery = Arc::new(AtomicUsize::new(0));
    let certs = Arc::new(AtomicUsize::new(0));
    let (d, c) = (discovery.clone(), certs.clone());
    let app = Router::new()
        .route(
            "/auth/realms/academy/.well-known/openid-configuration",
            get(move || {
                d.fetch_add(1, Ordering::SeqCst);
                async { axum::Json(json!({"issuer": ISSUER, "jwks_uri": "ignored"})) }
            }),
        )
        .route(
            "/auth/realms/academy/protocol/openid-connect/certs",
            get(move || {
                c.fetch_add(1, Ordering::SeqCst);
                async { axum::Json(json!({"keys": [common::app::realm_jwk()]})) }
            }),
        );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let address = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
    Realm { url: format!("http://{address}/auth/realms/academy"), discovery, certs }
}

fn verifier(url: &str) -> TokenVerifier {
    let vars = HashMap::from([("OIDC_AUTH_SERVER_URL".to_owned(), url.to_owned())]);
    TokenVerifier::remote(&Config::from_vars(&vars).unwrap()).unwrap()
}

fn bearer(token: &str) -> HeaderValue {
    HeaderValue::from_str(&format!("Bearer {token}")).unwrap()
}

#[tokio::test]
async fn keys_and_issuer_are_read_from_the_realm_once() {
    let realm = realm().await;
    let verifier = verifier(&realm.url);
    for _ in 0..3 {
        let caller = verifier.verify(Some(&bearer(&core_token()))).await.unwrap();
        assert!(caller.roles.contains(&"service".to_owned()));
    }
    assert_eq!((realm.discovery.load(Ordering::SeqCst), realm.certs.load(Ordering::SeqCst)), (1, 1));
}

#[tokio::test]
async fn an_unknown_key_id_does_not_hammer_the_realm() {
    let realm = realm().await;
    let verifier = verifier(&realm.url);
    let unknown = token_with(realm_key(), Some("rotated-away"), &core_service_claims());
    for _ in 0..3 {
        let refused = verifier.verify(Some(&bearer(&unknown))).await.unwrap_err();
        assert!(matches!(refused, AuthFailure::Denied(_)));
    }
    assert_eq!(realm.certs.load(Ordering::SeqCst), 1, "read once, then at most every 30 s");
}

#[tokio::test]
async fn a_configured_issuer_is_not_discovered() {
    let realm = realm().await;
    let vars = HashMap::from([
        ("OIDC_AUTH_SERVER_URL".to_owned(), realm.url.clone()),
        ("OIDC_ISSUER".to_owned(), "http://localhost:8090/auth/realms/academy".to_owned()),
    ]);
    let verifier = TokenVerifier::remote(&Config::from_vars(&vars).unwrap()).unwrap();
    let refused = verifier.verify(Some(&bearer(&core_token()))).await.unwrap_err();
    assert!(matches!(refused, AuthFailure::Denied(d) if d.reason == "issuer"));
    assert_eq!(realm.discovery.load(Ordering::SeqCst), 0);
}

#[tokio::test]
async fn an_unreachable_realm_is_503() {
    let sheets = PrintSheets::new(Arc::new(KrillaRenderer::new().unwrap()), Arc::new(SystemClock));
    let state = AppState::new(
        sheets,
        verifier("http://127.0.0.1:9/auth/realms/academy"),
        Arc::new(SecurityEvents::default()),
        1,
    );
    let answer =
        post_raw(&router(state), common::TEAM_ROSTER, Some(&core_token()), "application/json", b"{}".to_vec()).await;
    assert_eq!(answer.status, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(answer.json()["code"], "AUTH_UNAVAILABLE");
}

#[tokio::test]
async fn a_realm_answering_an_error_is_unavailable() {
    let app = Router::new().fallback(|| async { StatusCode::BAD_GATEWAY });
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let address = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
    let verifier = verifier(&format!("http://{address}/auth/realms/academy"));
    assert_eq!(verifier.verify(Some(&bearer(&core_token()))).await.unwrap_err(), AuthFailure::Unavailable);
    assert!(format!("{verifier:?}").contains("pdf-service"));
}
