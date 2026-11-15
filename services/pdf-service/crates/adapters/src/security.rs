//! Security events and their metric (ADR-0043), the Rust counterpart of `common-quarkus`: one WARN record of target
//! `hoops.security` per refused request, with the fields `security.event` (`authz_denied`), `security.kind`,
//! `security.outcome` (the HTTP status), `tenantId` (always empty: pdf-service has no tenant), `security.subject` (the
//! `sub` of a verified token only), `security.roles`, `security.resource` (`METHOD /route`) and `security.reason`;
//! and the counter `hoops_authz_denied_total{kind}` with every kind registered at 0. Never the token, an unverified
//! claim, a request value, a name or an e-mail; values are stripped of control characters and quotes and cut at 200.

use std::fmt::Write as _;
use std::sync::atomic::{AtomicU64, Ordering};

/// The kinds pdf-service decides (the others of ADR-0043 are about tenants, which it has none of).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DenialKind {
    /// 401: no bearer token.
    Unauthenticated,
    /// 401: a token that fails verification (reason: `expired`, `not_yet_valid`, `audience`, `signature`, `issuer`,
    /// `invalid`, `no_sub`).
    InvalidToken,
    /// 403: a verified token without the realm role `service`.
    RealmRole,
}

impl DenialKind {
    pub const ALL: [Self; 3] = [Self::Unauthenticated, Self::InvalidToken, Self::RealmRole];

    pub fn name(self) -> &'static str {
        match self {
            Self::Unauthenticated => "unauthenticated",
            Self::InvalidToken => "invalid_token",
            Self::RealmRole => "realm_role",
        }
    }

    pub fn status(self) -> u16 {
        match self {
            Self::Unauthenticated | Self::InvalidToken => 401,
            Self::RealmRole => 403,
        }
    }
}

/// A refused request, as the event records it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Denial {
    pub kind: DenialKind,
    pub reason: &'static str,
    pub subject: Option<String>,
    pub roles: Vec<String>,
}

/// Writes the events and counts them.
#[derive(Debug, Default)]
pub struct SecurityEvents {
    counts: [AtomicU64; 3],
}

impl SecurityEvents {
    pub fn deny(&self, denial: &Denial, resource: &str) {
        self.counts[Self::index(denial.kind)].fetch_add(1, Ordering::Relaxed);
        let subject = clean(denial.subject.as_deref().unwrap_or_default());
        let roles = clean(&denial.roles.join(","));
        let resource = clean(resource);
        let kind = denial.kind.name();
        let outcome = denial.kind.status();
        tracing::warn!(
            target: "hoops.security",
            tenantId = "",
            security.event = "authz_denied",
            security.kind = kind,
            security.outcome = outcome,
            security.subject = %subject,
            security.roles = %roles,
            security.resource = %resource,
            security.reason = denial.reason,
            "authz_denied kind={kind} outcome={outcome} tenant= subject={subject} roles={roles} resource=\"{resource}\" reason=\"{}\"",
            denial.reason
        );
    }

    pub fn count(&self, kind: DenialKind) -> u64 {
        self.counts[Self::index(kind)].load(Ordering::Relaxed)
    }

    /// The counter in the Prometheus text format (`/q/metrics`).
    pub fn prometheus(&self) -> String {
        let mut out = String::from(
            "# HELP hoops_authz_denied_total Requests refused by authentication or authorization (ADR-0043)\n\
             # TYPE hoops_authz_denied_total counter\n",
        );
        for kind in DenialKind::ALL {
            let _ = writeln!(out, "hoops_authz_denied_total{{kind=\"{}\"}} {}", kind.name(), self.count(kind));
        }
        out
    }

    fn index(kind: DenialKind) -> usize {
        match kind {
            DenialKind::Unauthenticated => 0,
            DenialKind::InvalidToken => 1,
            DenialKind::RealmRole => 2,
        }
    }
}

/// Log-injection guard: no control characters or quotes, at most 200 characters.
pub fn clean(value: &str) -> String {
    value.chars().filter(|c| !c.is_control() && *c != '"' && *c != '\'').take(200).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_kind_is_counted_from_zero() {
        let events = SecurityEvents::default();
        assert!(events.prometheus().contains("hoops_authz_denied_total{kind=\"realm_role\"} 0"));
        let denial = Denial { kind: DenialKind::InvalidToken, reason: "audience", subject: None, roles: vec![] };
        events.deny(&denial, "POST /internal/pdf/match-sheet");
        events.deny(&denial, "POST /internal/pdf/match-sheet");
        assert_eq!(events.count(DenialKind::InvalidToken), 2);
        assert_eq!(events.count(DenialKind::Unauthenticated), 0);
        let text = events.prometheus();
        assert!(text.contains("# TYPE hoops_authz_denied_total counter"));
        assert!(text.contains("hoops_authz_denied_total{kind=\"invalid_token\"} 2"));
        assert!(text.contains("hoops_authz_denied_total{kind=\"unauthenticated\"} 0"));
    }

    #[test]
    fn kinds_have_their_names_and_statuses() {
        let pairs: Vec<_> = DenialKind::ALL.iter().map(|k| (k.name(), k.status())).collect();
        assert_eq!(pairs, [("unauthenticated", 401), ("invalid_token", 401), ("realm_role", 403)]);
    }

    #[test]
    fn values_are_cleaned_for_the_log() {
        assert_eq!(clean("a\"b'c\nd\re"), "abcde");
        assert_eq!(clean(&"x".repeat(300)).len(), 200);
    }
}
