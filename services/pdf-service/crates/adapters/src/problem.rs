//! Problem+JSON (RFC 9457, `common.yaml#/components/schemas/Problem`): `type` `urn:hoops:problem:<slug>`, `title`,
//! `status`, `detail`, `instance`, `code` and `violations`. No stack trace, and (privacy finding P-11 of
//! `docs/security/privacy-threat-model.md`) never a value of the request: a violation names its field and a code, a
//! limit names the list and its maximum.

use axum::http::{HeaderValue, StatusCode, header};
use axum::response::{IntoResponse, Response};
use pdf_domain::{SheetError, Violation};
use serde::Serialize;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ProblemViolation {
    pub field: String,
    pub code: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Problem {
    #[serde(rename = "type")]
    pub kind: String,
    pub title: String,
    pub status: u16,
    pub detail: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instance: Option<String>,
    pub code: String,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub violations: Vec<ProblemViolation>,
}

impl Problem {
    pub fn new(status: StatusCode, slug: &str, code: &str, detail: &str) -> Self {
        Self {
            kind: format!("urn:hoops:problem:{slug}"),
            title: status.canonical_reason().unwrap_or("Error").to_owned(),
            status: status.as_u16(),
            detail: detail.to_owned(),
            instance: None,
            code: code.to_owned(),
            violations: Vec::new(),
        }
    }

    #[must_use]
    pub fn at(mut self, path: &str) -> Self {
        self.instance = Some(path.to_owned());
        self
    }

    pub fn validation(violations: Vec<ProblemViolation>) -> Self {
        Self {
            violations,
            ..Self::new(
                StatusCode::BAD_REQUEST,
                "validation",
                "VALIDATION_FAILED",
                "The body does not follow the contract; see violations.",
            )
        }
    }

    /// A refused sheet: 400 with its violations, or 422 `TOO_MANY_ROWS` naming the list.
    pub fn from_sheet(error: &SheetError) -> Self {
        match error {
            SheetError::Invalid(violations) => Self::validation(violations.iter().map(violation).collect()),
            SheetError::TooManyRows { field, max } => Self {
                violations: vec![ProblemViolation {
                    field: field.clone(),
                    code: "TOO_MANY_ROWS".to_owned(),
                    message: format!("at most {max} rows"),
                }],
                ..Self::new(
                    StatusCode::UNPROCESSABLE_ENTITY,
                    "domain-rule-violation",
                    "TOO_MANY_ROWS",
                    &format!("{field} holds more than {max} rows; send fewer."),
                )
            },
        }
    }

    pub fn unauthenticated() -> Self {
        Self::new(StatusCode::UNAUTHORIZED, "unauthorized", "UNAUTHENTICATED", "A bearer token is required.")
    }

    pub fn invalid_token() -> Self {
        Self::new(StatusCode::UNAUTHORIZED, "unauthorized", "INVALID_TOKEN", "The token is not valid for pdf-service.")
    }

    pub fn forbidden() -> Self {
        Self::new(StatusCode::FORBIDDEN, "forbidden", "FORBIDDEN", "The token lacks the realm role service.")
    }

    pub fn auth_unavailable() -> Self {
        Self::new(
            StatusCode::SERVICE_UNAVAILABLE,
            "upstream-unavailable",
            "AUTH_UNAVAILABLE",
            "The realm's signing keys could not be read; retry later.",
        )
    }

    pub fn too_large(limit: usize) -> Self {
        Self::new(
            StatusCode::PAYLOAD_TOO_LARGE,
            "payload-too-large",
            "PAYLOAD_TOO_LARGE",
            &format!("The body is over {} KiB.", limit / 1024),
        )
    }

    pub fn unsupported_media_type() -> Self {
        Self::new(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            "unsupported-media-type",
            "UNSUPPORTED_MEDIA_TYPE",
            "The body must be application/json.",
        )
    }

    pub fn internal() -> Self {
        Self::new(
            StatusCode::INTERNAL_SERVER_ERROR,
            "internal-error",
            "INTERNAL_ERROR",
            "The sheet could not be rendered.",
        )
    }

    pub fn not_found() -> Self {
        Self::new(StatusCode::NOT_FOUND, "not-found", "NOT_FOUND", "No such resource.")
    }

    pub fn method_not_allowed() -> Self {
        Self::new(
            StatusCode::METHOD_NOT_ALLOWED,
            "method-not-allowed",
            "METHOD_NOT_ALLOWED",
            "The resource does not support this method.",
        )
    }
}

fn violation(violation: &Violation) -> ProblemViolation {
    ProblemViolation {
        field: violation.field.clone(),
        code: violation.code.to_owned(),
        message: violation.message.to_owned(),
    }
}

impl IntoResponse for Problem {
    fn into_response(self) -> Response {
        let status = StatusCode::from_u16(self.status).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR);
        let body = serde_json::to_vec(&self).unwrap_or_default();
        let mut response = (status, body).into_response();
        response.headers_mut().insert(header::CONTENT_TYPE, HeaderValue::from_static("application/problem+json"));
        response.headers_mut().insert(header::CACHE_CONTROL, HeaderValue::from_static("no-store"));
        response
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn too_many_rows_names_the_list_and_its_limit() {
        let problem = Problem::from_sheet(&SheetError::TooManyRows { field: "players".into(), max: 60 });
        assert_eq!((problem.status, problem.code.as_str()), (422, "TOO_MANY_ROWS"));
        assert_eq!(problem.kind, "urn:hoops:problem:domain-rule-violation");
        assert_eq!(problem.title, "Unprocessable Entity");
        assert_eq!(problem.violations[0].field, "players");
        assert_eq!(problem.detail, "players holds more than 60 rows; send fewer.");
    }

    #[test]
    fn field_violations_are_a_validation_problem() {
        let problem =
            Problem::from_sheet(&SheetError::Invalid(vec![Violation::new("team.name", "BLANK", "must not be blank")]));
        assert_eq!((problem.status, problem.code.as_str()), (400, "VALIDATION_FAILED"));
        assert_eq!(
            problem.violations,
            [ProblemViolation { field: "team.name".into(), code: "BLANK".into(), message: "must not be blank".into() }]
        );
    }

    /// `(slug, status)` of every `ProblemType` of common-quarkus (the vocabulary `common.yaml`'s `Problem` refers to).
    fn shared_vocabulary() -> Vec<(String, u16)> {
        let path = format!(
            "{}/../../../../libs/common-quarkus/src/main/java/com/hoopsacademy/common/problem/ProblemType.java",
            env!("CARGO_MANIFEST_DIR")
        );
        let source = std::fs::read_to_string(path).expect("ProblemType.java");
        source
            .lines()
            .filter_map(|line| {
                let arguments = line
                    .trim()
                    .split_once('(')?
                    .1
                    .strip_suffix("),")
                    .or_else(|| line.trim().split_once('(')?.1.strip_suffix(");"))?;
                let mut parts = arguments.split(", ");
                let status = parts.next()?.parse().ok()?;
                let slug = parts.nth(1)?.trim_matches('"');
                Some((slug.to_owned(), status))
            })
            .collect()
    }

    /// Slugs the Java vocabulary lacks; Go's finance-service has `unsupported-media-type` too (X-11).
    const OWN_SLUGS: [&str; 2] = ["unsupported-media-type", "method-not-allowed"];

    #[test]
    fn problem_types_are_the_shared_vocabulary() {
        let vocabulary = shared_vocabulary();
        assert!(vocabulary.len() >= 10, "ProblemType.java parsed: {vocabulary:?}");
        let problems = [
            Problem::from_sheet(&SheetError::Invalid(vec![])),
            Problem::from_sheet(&SheetError::TooManyRows { field: "players".into(), max: 1 }),
            Problem::unauthenticated(),
            Problem::invalid_token(),
            Problem::forbidden(),
            Problem::auth_unavailable(),
            Problem::too_large(1024),
            Problem::unsupported_media_type(),
            Problem::internal(),
            Problem::not_found(),
            Problem::method_not_allowed(),
        ];
        for problem in problems {
            let slug = problem.kind.strip_prefix("urn:hoops:problem:").expect("a urn");
            match vocabulary.iter().find(|(name, _)| name == slug) {
                Some((_, status)) => assert_eq!(*status, problem.status, "{slug}"),
                None => assert!(OWN_SLUGS.contains(&slug), "{slug} is not in common-quarkus' ProblemType"),
            }
        }
    }

    #[test]
    fn every_problem_has_its_status_and_code() {
        let pairs: Vec<_> = [
            Problem::unauthenticated(),
            Problem::invalid_token(),
            Problem::forbidden(),
            Problem::auth_unavailable(),
            Problem::too_large(256 * 1024),
            Problem::unsupported_media_type(),
            Problem::internal(),
            Problem::not_found(),
            Problem::method_not_allowed(),
        ]
        .into_iter()
        .map(|p| (p.status, p.code))
        .collect();
        assert_eq!(
            pairs,
            [
                (401, "UNAUTHENTICATED".to_owned()),
                (401, "INVALID_TOKEN".to_owned()),
                (403, "FORBIDDEN".to_owned()),
                (503, "AUTH_UNAVAILABLE".to_owned()),
                (413, "PAYLOAD_TOO_LARGE".to_owned()),
                (415, "UNSUPPORTED_MEDIA_TYPE".to_owned()),
                (500, "INTERNAL_ERROR".to_owned()),
                (404, "NOT_FOUND".to_owned()),
                (405, "METHOD_NOT_ALLOWED".to_owned())
            ]
        );
        assert_eq!(Problem::too_large(256 * 1024).detail, "The body is over 256 KiB.");
    }
}
