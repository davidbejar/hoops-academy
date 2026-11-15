//! Configuration from the environment (12-factor, as the Quarkus services): every key has a local default, the chart
//! and compose set the in-cluster values. No secret: the service only verifies tokens.

use std::collections::HashMap;

/// What `main` needs to start the service.
#[derive(Debug, Clone, PartialEq)]
pub struct Config {
    /// `PDF_HTTP_PORT` (default 8084).
    pub port: u16,
    /// `OIDC_AUTH_SERVER_URL`: the realm as the service reaches it (back channel), e.g.
    /// `http://keycloak:8080/auth/realms/academy`. The signing keys come from `<url>/protocol/openid-connect/certs`.
    pub auth_server_url: String,
    /// `OIDC_ISSUER`: the `iss` tokens must carry. Empty (default): the `issuer` of the realm's discovery document,
    /// which Keycloak derives from its public hostname (`KC_HOSTNAME`), the value it puts in every token.
    pub issuer: Option<String>,
    /// `OIDC_AUDIENCE` (default `pdf-service`, ADR-0034).
    pub audience: String,
    /// `OTEL_SDK_DISABLED` (default true) and `OTEL_EXPORTER_OTLP_ENDPOINT` (OTLP over HTTP/protobuf, port 4318).
    pub otlp_endpoint: Option<String>,
    /// `OTEL_TRACES_SAMPLER_ARG`: ratio of root spans kept (default 0.1; parent-based).
    pub traces_sample_ratio: f64,
    /// `OTEL_RESOURCE_ATTRIBUTES` is read by the SDK itself.
    pub log_filter: String,
}

impl Config {
    /// Reads the configuration from `vars` (the process environment in `main`, a map in tests).
    pub fn from_vars(vars: &HashMap<String, String>) -> Result<Self, String> {
        let get = |key: &str| vars.get(key).map(|v| v.trim().to_owned()).filter(|v| !v.is_empty());
        let port = match get("PDF_HTTP_PORT") {
            Some(port) => port.parse().map_err(|_| "PDF_HTTP_PORT is not a port number".to_owned())?,
            None => 8084,
        };
        let sdk_disabled = get("OTEL_SDK_DISABLED").is_none_or(|v| v.eq_ignore_ascii_case("true"));
        let ratio = match get("OTEL_TRACES_SAMPLER_ARG") {
            Some(ratio) => ratio
                .parse::<f64>()
                .ok()
                .filter(|r| (0.0..=1.0).contains(r))
                .ok_or_else(|| "OTEL_TRACES_SAMPLER_ARG is not a ratio between 0 and 1".to_owned())?,
            None => 0.1,
        };
        Ok(Self {
            port,
            auth_server_url: get("OIDC_AUTH_SERVER_URL")
                .unwrap_or_else(|| "http://localhost:8080/auth/realms/academy".to_owned())
                .trim_end_matches('/')
                .to_owned(),
            issuer: get("OIDC_ISSUER"),
            audience: get("OIDC_AUDIENCE").unwrap_or_else(|| "pdf-service".to_owned()),
            otlp_endpoint: if sdk_disabled { None } else { get("OTEL_EXPORTER_OTLP_ENDPOINT") },
            traces_sample_ratio: ratio,
            log_filter: get("PDF_LOG").unwrap_or_else(|| "info".to_owned()),
        })
    }

    /// The realm's JSON Web Key Set (Keycloak's fixed path below the realm).
    pub fn certs_url(&self) -> String {
        format!("{}/protocol/openid-connect/certs", self.auth_server_url)
    }

    /// The realm's discovery document.
    pub fn discovery_url(&self) -> String {
        format!("{}/.well-known/openid-configuration", self.auth_server_url)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn vars(pairs: &[(&str, &str)]) -> HashMap<String, String> {
        pairs.iter().map(|(k, v)| ((*k).to_owned(), (*v).to_owned())).collect()
    }

    #[test]
    fn defaults_fit_the_host() {
        let config = Config::from_vars(&HashMap::new()).unwrap();
        assert_eq!(config.port, 8084);
        assert_eq!(config.auth_server_url, "http://localhost:8080/auth/realms/academy");
        assert_eq!(config.issuer, None);
        assert_eq!(config.audience, "pdf-service");
        assert_eq!(config.otlp_endpoint, None);
        assert!((config.traces_sample_ratio - 0.1).abs() < f64::EPSILON);
        assert_eq!(config.log_filter, "info");
    }

    #[test]
    fn the_chart_values_are_read() {
        let config = Config::from_vars(&vars(&[
            ("PDF_HTTP_PORT", "9000"),
            ("OIDC_AUTH_SERVER_URL", "http://keycloak:8080/auth/realms/academy/"),
            ("OIDC_ISSUER", "http://localhost:8090/auth/realms/academy"),
            ("OTEL_SDK_DISABLED", "false"),
            ("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector.hoops.svc.cluster.local:4318"),
            ("OTEL_TRACES_SAMPLER_ARG", "1.0"),
            ("PDF_LOG", "debug"),
        ]))
        .unwrap();
        assert_eq!(config.port, 9000);
        assert_eq!(config.certs_url(), "http://keycloak:8080/auth/realms/academy/protocol/openid-connect/certs");
        assert_eq!(config.discovery_url(), "http://keycloak:8080/auth/realms/academy/.well-known/openid-configuration");
        assert_eq!(config.issuer.as_deref(), Some("http://localhost:8090/auth/realms/academy"));
        assert_eq!(config.otlp_endpoint.as_deref(), Some("http://otel-collector.hoops.svc.cluster.local:4318"));
        assert!((config.traces_sample_ratio - 1.0).abs() < f64::EPSILON);
        assert_eq!(config.log_filter, "debug");
    }

    #[test]
    fn the_exporter_stays_off_while_the_sdk_is_disabled() {
        let config = Config::from_vars(&vars(&[("OTEL_EXPORTER_OTLP_ENDPOINT", "http://collector:4318")])).unwrap();
        assert_eq!(config.otlp_endpoint, None);
    }

    #[test]
    fn wrong_values_are_refused_by_name() {
        assert_eq!(
            Config::from_vars(&vars(&[("PDF_HTTP_PORT", "http")])),
            Err("PDF_HTTP_PORT is not a port number".to_owned())
        );
        assert!(Config::from_vars(&vars(&[("OTEL_TRACES_SAMPLER_ARG", "2")])).unwrap_err().contains("ratio"));
    }
}
