//! Bearer token verification (ADR-0034, ADR-0043): an RS256 access token of realm `academy`, signed by a key of the
//! realm's JWKS, issued by the realm, not expired, whose `aud` contains this service's audience (`pdf-service`), with
//! a `sub` and the realm role `service`. The keys are fetched from Keycloak on first use and again when a token names
//! an unknown key id (at most every 30 s); the issuer comes from the realm's discovery document unless configured.
//! The only outbound calls of the service are these two reads of Keycloak.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use axum::http::HeaderValue;
use jsonwebtoken::errors::ErrorKind;
use jsonwebtoken::jwk::Jwk;
use jsonwebtoken::{Algorithm, DecodingKey, Validation};
use serde::Deserialize;
use serde_json::Value;
use tokio::sync::Mutex;

use crate::config::Config;
use crate::security::{Denial, DenialKind};

/// The realm role every caller needs (`/internal/**`, ADR-0034).
pub const SERVICE_ROLE: &str = "service";
const REFRESH_EVERY: Duration = Duration::from_secs(30);
const LEEWAY_SECONDS: u64 = 5;

/// A verified caller: core-service or game-service.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Caller {
    pub subject: String,
    pub roles: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AuthFailure {
    /// 401 / 403 with a security event.
    Denied(Denial),
    /// 503: the realm's keys or discovery document could not be read.
    Unavailable,
}

#[derive(Deserialize)]
struct Claims {
    sub: Option<String>,
    realm_access: Option<RealmAccess>,
}

#[derive(Deserialize)]
struct RealmAccess {
    #[serde(default)]
    roles: Vec<String>,
}

enum Source {
    Fixed,
    Remote { client: reqwest::Client, certs_url: String, discovery_url: String },
}

#[derive(Default)]
struct Cache {
    issuer: Option<String>,
    keys: HashMap<String, DecodingKey>,
    fetched: Option<Instant>,
}

/// Verifies bearer tokens against the realm.
pub struct TokenVerifier {
    audience: String,
    source: Source,
    cache: Mutex<Cache>,
}

impl std::fmt::Debug for TokenVerifier {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("TokenVerifier").field("audience", &self.audience).finish_non_exhaustive()
    }
}

impl TokenVerifier {
    /// Fixed issuer and keys (tests, and any environment that mounts the realm's JWKS).
    pub fn fixed(issuer: &str, jwks: &Value, audience: &str) -> Self {
        let cache = Cache { issuer: Some(issuer.to_owned()), keys: signing_keys(jwks), fetched: Some(Instant::now()) };
        Self { audience: audience.to_owned(), source: Source::Fixed, cache: Mutex::new(cache) }
    }

    /// Keys and (unless configured) issuer from Keycloak, read when first needed.
    pub fn remote(config: &Config) -> Result<Self, String> {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(5))
            .redirect(reqwest::redirect::Policy::none())
            .build()
            .map_err(|_| "cannot build the HTTP client for the realm".to_owned())?;
        let cache = Cache { issuer: config.issuer.clone(), ..Cache::default() };
        Ok(Self {
            audience: config.audience.clone(),
            source: Source::Remote { client, certs_url: config.certs_url(), discovery_url: config.discovery_url() },
            cache: Mutex::new(cache),
        })
    }

    /// The caller of a request with this `Authorization` header, or why it is refused.
    pub async fn verify(&self, authorization: Option<&HeaderValue>) -> Result<Caller, AuthFailure> {
        let token = bearer(authorization).ok_or_else(|| denied(DenialKind::Unauthenticated, "no bearer token"))?;
        let header = jsonwebtoken::decode_header(token).map_err(|_| denied(DenialKind::InvalidToken, "invalid"))?;
        if header.alg != Algorithm::RS256 {
            return Err(denied(DenialKind::InvalidToken, "invalid"));
        }
        let kid = header.kid.ok_or_else(|| denied(DenialKind::InvalidToken, "signature"))?;
        let (issuer, key) = self.key(&kid).await?;
        let key = key.ok_or_else(|| denied(DenialKind::InvalidToken, "signature"))?;

        let mut validation = Validation::new(Algorithm::RS256);
        validation.set_issuer(&[issuer]);
        validation.set_audience(&[&self.audience]);
        validation.set_required_spec_claims(&["exp", "iss", "aud"]);
        validation.validate_nbf = true;
        validation.leeway = LEEWAY_SECONDS;
        let claims = jsonwebtoken::decode::<Claims>(token, &key, &validation)
            .map_err(|error| denied(DenialKind::InvalidToken, reason(error.kind())))?
            .claims;

        let subject =
            claims.sub.filter(|sub| !sub.is_empty()).ok_or_else(|| denied(DenialKind::InvalidToken, "no_sub"))?;
        let roles = claims.realm_access.map(|access| access.roles).unwrap_or_default();
        if !roles.iter().any(|role| role == SERVICE_ROLE) {
            return Err(AuthFailure::Denied(Denial {
                kind: DenialKind::RealmRole,
                reason: "missing realm role service",
                subject: Some(subject),
                roles,
            }));
        }
        Ok(Caller { subject, roles })
    }

    /// The issuer and the key `kid`; an unknown key id refreshes the keys at most every 30 s.
    async fn key(&self, kid: &str) -> Result<(String, Option<DecodingKey>), AuthFailure> {
        let mut cache = self.cache.lock().await;
        let stale = cache.fetched.is_none_or(|at| at.elapsed() >= REFRESH_EVERY);
        if !cache.keys.contains_key(kid)
            && stale
            && let Source::Remote { client, certs_url, .. } = &self.source
        {
            let jwks = fetch(client, certs_url).await?;
            cache.keys = signing_keys(&jwks);
            cache.fetched = Some(Instant::now());
        }
        if cache.issuer.is_none()
            && let Source::Remote { client, discovery_url, .. } = &self.source
        {
            let discovery = fetch(client, discovery_url).await?;
            let issuer = discovery.get("issuer").and_then(Value::as_str).ok_or(AuthFailure::Unavailable)?;
            cache.issuer = Some(issuer.to_owned());
        }
        let issuer = cache.issuer.clone().ok_or(AuthFailure::Unavailable)?;
        Ok((issuer, cache.keys.get(kid).cloned()))
    }
}

async fn fetch(client: &reqwest::Client, url: &str) -> Result<Value, AuthFailure> {
    let response = client.get(url).send().await.map_err(|_| unavailable(url))?;
    if !response.status().is_success() {
        return Err(unavailable(url));
    }
    response.json::<Value>().await.map_err(|_| unavailable(url))
}

fn unavailable(url: &str) -> AuthFailure {
    tracing::warn!(target: "pdf_service::auth", url, "the realm could not be read");
    AuthFailure::Unavailable
}

/// The RSA signing keys of a JWKS by key id; encryption keys and keys this library cannot read are skipped.
fn signing_keys(jwks: &Value) -> HashMap<String, DecodingKey> {
    let keys = jwks.get("keys").and_then(Value::as_array).cloned().unwrap_or_default();
    keys.into_iter()
        .filter(|key| key.get("use").and_then(Value::as_str).is_none_or(|usage| usage == "sig"))
        .filter(|key| key.get("kty").and_then(Value::as_str) == Some("RSA"))
        .filter_map(|key| serde_json::from_value::<Jwk>(key).ok())
        .filter_map(|jwk| Some((jwk.common.key_id.clone()?, DecodingKey::from_jwk(&jwk).ok()?)))
        .collect()
}

fn bearer(authorization: Option<&HeaderValue>) -> Option<&str> {
    let value = authorization?.to_str().ok()?;
    let (scheme, token) = value.split_once(' ')?;
    let token = token.trim();
    (scheme.eq_ignore_ascii_case("bearer") && !token.is_empty()).then_some(token)
}

fn denied(kind: DenialKind, reason: &'static str) -> AuthFailure {
    AuthFailure::Denied(Denial { kind, reason, subject: None, roles: Vec::new() })
}

/// jose reasons as ADR-0043 names them.
fn reason(kind: &ErrorKind) -> &'static str {
    match kind {
        ErrorKind::ExpiredSignature => "expired",
        ErrorKind::ImmatureSignature => "not_yet_valid",
        ErrorKind::InvalidAudience => "audience",
        ErrorKind::InvalidIssuer => "issuer",
        ErrorKind::InvalidSignature => "signature",
        _ => "invalid",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_a_bearer_token_is_read() {
        let value = |v: &str| HeaderValue::from_str(v).unwrap();
        assert_eq!(bearer(Some(&value("Bearer abc"))), Some("abc"));
        assert_eq!(bearer(Some(&value("bearer  abc "))), Some("abc"));
        assert_eq!(bearer(Some(&value("Basic abc"))), None);
        assert_eq!(bearer(Some(&value("Bearer "))), None);
        assert_eq!(bearer(Some(&value("Bearer"))), None);
        assert_eq!(bearer(None), None);
    }

    #[test]
    fn jose_errors_get_the_reasons_of_adr_0043() {
        assert_eq!(reason(&ErrorKind::ExpiredSignature), "expired");
        assert_eq!(reason(&ErrorKind::ImmatureSignature), "not_yet_valid");
        assert_eq!(reason(&ErrorKind::InvalidAudience), "audience");
        assert_eq!(reason(&ErrorKind::InvalidIssuer), "issuer");
        assert_eq!(reason(&ErrorKind::InvalidSignature), "signature");
        assert_eq!(reason(&ErrorKind::InvalidToken), "invalid");
    }

    #[test]
    fn encryption_and_unreadable_keys_are_skipped() {
        let jwks = serde_json::json!({"keys": [
            {"kid": "enc", "kty": "RSA", "use": "enc", "alg": "RSA-OAEP", "n": "AQAB", "e": "AQAB"},
            {"kid": "ec", "kty": "EC", "use": "sig", "crv": "P-256", "x": "AA", "y": "AA"},
            {"kid": "odd", "kty": "RSA", "use": "sig", "alg": "RS256", "n": 7, "e": "AQAB"},
            {"kty": "RSA", "use": "sig", "n": "AQAB", "e": "AQAB"}
        ]});
        assert!(signing_keys(&jwks).is_empty());
        assert!(signing_keys(&serde_json::json!({})).is_empty());
    }
}
