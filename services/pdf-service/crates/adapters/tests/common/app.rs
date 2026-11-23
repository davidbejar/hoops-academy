//! The service as the tests drive it: the real router, renderer and verifier, a fixed clock and a test realm (an RSA
//! key made at start; nothing is committed) that signs tokens like Keycloak's.

use std::sync::{Arc, OnceLock};

use axum::Router;
use axum::body::Body;
use axum::http::{HeaderMap, Method, Request, StatusCode};
use base64::Engine as _;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use http_body_util::BodyExt as _;
use jiff::Timestamp;
use jsonwebtoken::{Algorithm, EncodingKey, Header};
use pdf_adapters::auth::TokenVerifier;
use pdf_adapters::http::{AppState, router};
use pdf_adapters::render::KrillaRenderer;
use pdf_adapters::security::SecurityEvents;
use pdf_application::{Clock, PrintSheets};
use rsa::pkcs1::EncodeRsaPrivateKey as _;
use rsa::traits::PublicKeyParts as _;
use serde_json::{Value, json};
use tower::ServiceExt as _;

pub const ISSUER: &str = "http://localhost:8080/auth/realms/academy";
pub const KID: &str = "test-key";

struct FixedClock;

impl Clock for FixedClock {
    fn now(&self) -> Timestamp {
        super::printed_at()
    }
}

/// A signing key and its JWKS entry.
pub struct RealmKey {
    encoding: EncodingKey,
    jwk: Value,
}

fn make_key(kid: &str) -> RealmKey {
    let private = <rsa::PrivateKey as rsa::Generate>::generate();
    let der = private.to_pkcs1_der().expect("DER");
    let jwk = json!({
        "kid": kid, "kty": "RSA", "alg": "RS256", "use": "sig",
        "n": URL_SAFE_NO_PAD.encode(private.n_bytes()), "e": URL_SAFE_NO_PAD.encode(private.e_bytes())
    });
    RealmKey { encoding: EncodingKey::from_rsa_der(der.as_bytes()), jwk }
}

/// The realm's key (shared by the tests of one binary: generating one takes a moment).
pub fn realm_key() -> &'static RealmKey {
    static KEY: OnceLock<RealmKey> = OnceLock::new();
    KEY.get_or_init(|| make_key(KID))
}

pub struct Service {
    pub router: Router,
    pub events: Arc<SecurityEvents>,
}

pub fn service() -> Service {
    let events = Arc::new(SecurityEvents::default());
    let sheets = PrintSheets::new(Arc::new(KrillaRenderer::new().expect("fonts")), Arc::new(FixedClock));
    let verifier = TokenVerifier::fixed(ISSUER, &json!({"keys": [realm_key().jwk.clone()]}), "pdf-service");
    Service { router: router(AppState::new(sheets, verifier, events.clone(), 2)), events }
}

/// Claims of a client-credentials token of core-service as Keycloak issues it (ADR-0034 mappers).
pub fn core_service_claims() -> Value {
    let now = Timestamp::now().as_second();
    json!({
        "iss": ISSUER, "sub": "5b1f0c2e-service-account-core", "azp": "core-service", "typ": "Bearer",
        "aud": ["game-service", "athlete-service", "pdf-service", "realm-management", "account"],
        "exp": now + 300, "iat": now, "realm_access": {"roles": ["service", "default-roles-academy"]}
    })
}

/// Claims of a token of the web client: its audiences are core, game and athlete, never pdf-service.
pub fn web_claims() -> Value {
    let now = Timestamp::now().as_second();
    json!({
        "iss": ISSUER, "sub": "user-1", "azp": "web", "typ": "Bearer",
        "aud": ["core-service", "game-service", "athlete-service"], "exp": now + 300, "iat": now,
        "realm_access": {"roles": ["default-roles-academy", "service"]}
    })
}

pub fn token_with(key: &RealmKey, kid: Option<&str>, claims: &Value) -> String {
    let mut header = Header::new(Algorithm::RS256);
    header.kid = kid.map(str::to_owned);
    jsonwebtoken::encode(&header, claims, &key.encoding).expect("a token")
}

pub fn token(claims: &Value) -> String {
    token_with(realm_key(), Some(KID), claims)
}

pub fn core_token() -> String {
    token(&core_service_claims())
}

/// `token` with its signature changed: what a key the realm does not publish would produce.
pub fn tampered(token: &str) -> String {
    let (signed, signature) = token.rsplit_once('.').expect("a JWT");
    let mut signature = signature.to_owned();
    let first = if signature.starts_with('A') { 'B' } else { 'A' };
    signature.replace_range(..1, &first.to_string());
    format!("{signed}.{signature}")
}

pub struct Answer {
    pub status: StatusCode,
    pub headers: HeaderMap,
    pub body: Vec<u8>,
}

impl Answer {
    pub fn json(&self) -> Value {
        serde_json::from_slice(&self.body).expect("a JSON body")
    }

    pub fn header(&self, name: &str) -> &str {
        self.headers.get(name).and_then(|v| v.to_str().ok()).unwrap_or_default()
    }
}

pub async fn call(router: &Router, method: Method, path: &str, headers: &[(&str, &str)], body: Vec<u8>) -> Answer {
    let mut request = Request::builder().method(method).uri(path);
    for (name, value) in headers {
        request = request.header(*name, *value);
    }
    let response = router.clone().oneshot(request.body(Body::from(body)).expect("a request")).await.expect("an answer");
    let status = response.status();
    let headers = response.headers().clone();
    let body = response.into_body().collect().await.expect("a body").to_bytes().to_vec();
    Answer { status, headers, body }
}

/// A POST of `body` as `content_type`, with a bearer token when there is one.
pub async fn post_raw(router: &Router, path: &str, token: Option<&str>, content_type: &str, body: Vec<u8>) -> Answer {
    let authorization = token.map(|token| format!("Bearer {token}"));
    let mut headers = vec![("content-type", content_type)];
    if let Some(value) = authorization.as_deref() {
        headers.push(("authorization", value));
    }
    call(router, Method::POST, path, &headers, body).await
}

/// A POST with a JSON body and a bearer token when there is one.
pub async fn post_json(router: &Router, path: &str, token: Option<&str>, body: &Value) -> Answer {
    post_raw(router, path, token, "application/json", serde_json::to_vec(body).expect("JSON")).await
}

/// A POST with a JSON body and core-service's token.
pub async fn post(router: &Router, path: &str, body: &Value) -> Answer {
    post_json(router, path, Some(&core_token()), body).await
}

pub fn fixture(name: &str) -> Value {
    let path = format!("{}/tests/fixtures/{name}", env!("CARGO_MANIFEST_DIR"));
    serde_json::from_str(&std::fs::read_to_string(path).expect("fixture")).expect("fixture JSON")
}

/// The realm key's JWKS entry.
pub fn realm_jwk() -> Value {
    realm_key().jwk.clone()
}
