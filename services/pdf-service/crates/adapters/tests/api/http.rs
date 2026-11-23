//! The HTTP API end to end in process: authentication (ADR-0034), security events (ADR-0043), limits, Problem+JSON
//! that never repeats a request value (P-11) and the PDF answer. Logs and spans: `logs.rs`.

use crate::common;

use axum::http::{Method, StatusCode};
use common::app::{
    Answer, call, core_service_claims, core_token, fixture, post, post_json, post_raw, service, tampered, token,
    token_with, web_claims,
};
use common::{MATCH_SHEET, TEAM_ROSTER, assert_no_request_values, pdf_text, with, without};
use pdf_adapters::security::DenialKind;
use serde_json::{Value, json};

fn problem(answer: &Answer) -> Value {
    assert_eq!(answer.header("content-type"), "application/problem+json", "{}", String::from_utf8_lossy(&answer.body));
    answer.json()
}

async fn post_with_token(path: &str, bearer: Option<&str>, body: &Value) -> (Answer, common::app::Service) {
    let service = service();
    let answer = post_json(&service.router, path, bearer, body).await;
    (answer, service)
}

#[tokio::test]
async fn core_renders_a_match_sheet_as_a_pdf_download() {
    let service = service();
    let answer = post(&service.router, MATCH_SHEET, &fixture("match-sheet.json")).await;
    assert_eq!(answer.status, StatusCode::OK, "{}", String::from_utf8_lossy(&answer.body));
    assert_eq!(answer.header("content-type"), "application/pdf");
    assert_eq!(answer.header("cache-control"), "no-store");
    assert_eq!(answer.header("x-content-type-options"), "nosniff");
    assert_eq!(
        answer.header("content-disposition"),
        "attachment; filename=\"hoops-academia-nandu-match-sheet-u12-leones-cb-halcones-20261115.pdf\""
    );
    let text = pdf_text(&answer.body);
    assert!(text.contains("Acta del partido") && text.contains("Lucía Martínez *"), "{text}");
}

#[tokio::test]
async fn a_team_roster_is_rendered_in_the_requested_language() {
    let service = service();
    let answer = post(&service.router, TEAM_ROSTER, &fixture("team-roster.json")).await;
    assert_eq!(answer.status, StatusCode::OK);
    assert_eq!(
        answer.header("content-disposition"),
        "attachment; filename=\"hoops-garuda-hoops-roster-u12-elang-20261115.pdf\""
    );
    let text = pdf_text(&answer.body);
    for expected in ["Daftar tim", "Wijaya, Sari", "Naik kategori (+1)", "Wali: Wijaya, Agus", "Pelatih"] {
        assert!(text.contains(expected), "{expected} in {text}");
    }
}

#[tokio::test]
async fn the_same_request_gives_the_same_bytes() {
    let service = service();
    let first = post(&service.router, TEAM_ROSTER, &fixture("team-roster.json")).await;
    let second = post(&service.router, TEAM_ROSTER, &fixture("team-roster.json")).await;
    assert_eq!(first.body, second.body);
}

#[tokio::test]
async fn without_a_token_it_is_401_and_a_security_event() {
    let (answer, service) = post_with_token(MATCH_SHEET, None, &fixture("match-sheet.json")).await;
    assert_eq!(answer.status, StatusCode::UNAUTHORIZED);
    assert_eq!(answer.header("www-authenticate"), "Bearer");
    let body = problem(&answer);
    assert_eq!(body["code"], "UNAUTHENTICATED");
    assert_eq!(body["instance"], MATCH_SHEET);
    assert_eq!(service.events.count(DenialKind::Unauthenticated), 1);
}

#[tokio::test]
async fn a_web_client_token_is_refused() {
    // the browser never calls pdf-service (decision 89): the web client's audiences do not include it
    let (answer, service) =
        post_with_token(MATCH_SHEET, Some(&token(&web_claims())), &fixture("match-sheet.json")).await;
    assert_eq!(answer.status, StatusCode::UNAUTHORIZED);
    assert_eq!(problem(&answer)["code"], "INVALID_TOKEN");
    assert_eq!(service.events.count(DenialKind::InvalidToken), 1);
}

#[tokio::test]
async fn tokens_that_fail_verification_are_401() {
    let mut expired = core_service_claims();
    expired["exp"] = json!(jiff::Timestamp::now().as_second() - 120);
    let mut early = core_service_claims();
    early["nbf"] = json!(jiff::Timestamp::now().as_second() + 600);
    let mut other_issuer = core_service_claims();
    other_issuer["iss"] = json!("http://evil.example/realms/academy");
    let mut no_sub = core_service_claims();
    no_sub.as_object_mut().unwrap().remove("sub");
    let tokens = [
        token(&expired),
        token(&early),
        token(&other_issuer),
        token(&no_sub),
        tampered(&core_token()),
        token_with(common::app::realm_key(), Some("unknown-kid"), &core_service_claims()),
        token_with(common::app::realm_key(), None, &core_service_claims()),
        "not.a.jwt".to_owned(),
    ];
    for bearer in &tokens {
        let (answer, service) = post_with_token(TEAM_ROSTER, Some(bearer), &fixture("team-roster.json")).await;
        assert_eq!(answer.status, StatusCode::UNAUTHORIZED, "{bearer}");
        assert_eq!(problem(&answer)["code"], "INVALID_TOKEN");
        assert_eq!(service.events.count(DenialKind::InvalidToken), 1);
    }
}

#[tokio::test]
async fn a_token_that_expired_a_moment_ago_is_refused() {
    // no clock leeway, like the Java services (Quarkus OIDC without lifespan-grace): ADR-0064
    let mut claims = core_service_claims();
    claims["exp"] = json!(jiff::Timestamp::now().as_second() - 2);
    let (answer, service) = post_with_token(TEAM_ROSTER, Some(&token(&claims)), &fixture("team-roster.json")).await;
    assert_eq!(answer.status, StatusCode::UNAUTHORIZED);
    assert_eq!(service.events.count(DenialKind::InvalidToken), 1);
}

#[tokio::test]
async fn a_token_for_pdf_service_without_the_service_role_is_403() {
    let mut claims = core_service_claims();
    claims["realm_access"] = json!({"roles": ["default-roles-academy"]});
    let (answer, service) = post_with_token(MATCH_SHEET, Some(&token(&claims)), &fixture("match-sheet.json")).await;
    assert_eq!(answer.status, StatusCode::FORBIDDEN);
    assert_eq!(problem(&answer)["code"], "FORBIDDEN");
    assert_eq!(service.events.count(DenialKind::RealmRole), 1);
}

#[tokio::test]
async fn a_body_over_256_kib_is_413() {
    let service = service();
    let mut body = fixture("team-roster.json");
    body["team"]["name"] = json!("x".repeat(300 * 1024));
    let answer = post(&service.router, TEAM_ROSTER, &body).await;
    assert_eq!(answer.status, StatusCode::PAYLOAD_TOO_LARGE);
    assert_eq!(problem(&answer)["code"], "PAYLOAD_TOO_LARGE");
}

#[tokio::test]
async fn a_body_that_is_not_json_is_415() {
    let service = service();
    let answer = post_raw(&service.router, MATCH_SHEET, Some(&core_token()), "text/html", b"<p>hi</p>".to_vec()).await;
    assert_eq!(answer.status, StatusCode::UNSUPPORTED_MEDIA_TYPE);
    assert_eq!(problem(&answer)["code"], "UNSUPPORTED_MEDIA_TYPE");
}

#[tokio::test]
async fn too_many_players_is_422_naming_the_list_never_the_children() {
    let service = service();
    let mut body = fixture("team-roster.json");
    let child = body["players"][0].clone();
    body["players"] = Value::Array(vec![child; 61]);
    let answer = post(&service.router, TEAM_ROSTER, &body).await;
    assert_eq!(answer.status, StatusCode::UNPROCESSABLE_ENTITY);
    let problem = problem(&answer);
    assert_eq!(problem["code"], "TOO_MANY_ROWS");
    assert_eq!(problem["violations"][0]["field"], "players");
    assert_no_request_values(&answer.body, "the answer");
}

#[tokio::test]
async fn validation_failures_name_the_field_never_the_value() {
    let service = service();
    let cases: Vec<(Value, &str, &str)> = vec![
        (
            with(&fixture("team-roster.json"), "/academy/timeZone", json!("Wijaya/Sari")),
            "academy.timeZone",
            "INVALID_TIME_ZONE",
        ),
        (with(&fixture("team-roster.json"), "/players/0/familyName", json!(" ")), "players[0].familyName", "BLANK"),
        (
            with(&fixture("team-roster.json"), "/players/0/jerseyNumber", json!("Sari")),
            "players[0].jerseyNumber",
            "INVALID_JERSEY_NUMBER",
        ),
        (with(&fixture("team-roster.json"), "/players/0/gender", json!("Sari Wijaya")), "players[0].gender", "INVALID"),
        (
            with(&fixture("team-roster.json"), "/players/0/nickname", json!("Sari")),
            "players[0].nickname",
            "UNKNOWN_PROPERTY",
        ),
        (without(&fixture("team-roster.json"), "/players/0/joinedOn"), "players[0].joinedOn", "REQUIRED"),
        (
            with(&fixture("team-roster.json"), "/players/0/phone", json!("Sari\nWijaya")),
            "players[0].phone",
            "CONTROL_CHARACTER",
        ),
    ];
    for (body, field, code) in cases {
        let answer = post(&service.router, TEAM_ROSTER, &body).await;
        assert_eq!(answer.status, StatusCode::BAD_REQUEST, "{field}");
        let problem = problem(&answer);
        assert_eq!(problem["code"], "VALIDATION_FAILED");
        assert_eq!(
            (problem["violations"][0]["field"].as_str(), problem["violations"][0]["code"].as_str()),
            (Some(field), Some(code))
        );
        assert_no_request_values(&answer.body, "the answer");
    }
    let answer =
        post(&service.router, MATCH_SHEET, &with(&fixture("match-sheet.json"), "/players/0/stats/points", json!(-3)))
            .await;
    assert_eq!(answer.status, StatusCode::BAD_REQUEST);
    assert_eq!(problem(&answer)["violations"][0]["field"], "players[0].stats.points");
}

/// What a date, an instant and a zone id may look like does not depend on the date-time crate: ISO 8601 with an
/// offset for an instant, `yyyy-MM-dd` for a day, the exact IANA id for a zone.
#[tokio::test]
async fn instants_days_and_zone_ids_are_strict() {
    let service = service();
    let accepted: Vec<(&str, &str, Value)> = vec![
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14T09:00:00Z")),
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14T10:00:00+01:00")),
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14T09:00:00.250Z")),
        (MATCH_SHEET, "/academy/timeZone", json!("UTC")),
        (TEAM_ROSTER, "/academy/timeZone", json!("America/Argentina/Buenos_Aires")),
        (TEAM_ROSTER, "/players/0/joinedOn", json!("2024-02-29")),
    ];
    let refused: Vec<(&str, &str, Value)> = vec![
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14T09:00:00")),
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14")),
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14T09:00:00+01:00[Europe/Madrid]")),
        (MATCH_SHEET, "/match/scheduledAt", json!("2026-11-14T09:00Z")),
        (MATCH_SHEET, "/match/scheduledAt", json!("20261114T090000Z")),
        (MATCH_SHEET, "/match/scheduledAt", json!(1_794_646_800)),
        (MATCH_SHEET, "/academy/timeZone", json!("europe/madrid")),
        (MATCH_SHEET, "/academy/timeZone", json!("+01:00")),
        (MATCH_SHEET, "/academy/timeZone", json!("")),
        (TEAM_ROSTER, "/players/0/joinedOn", json!("2026-02-30")),
        (TEAM_ROSTER, "/players/0/joinedOn", json!("2026-11-14T00:00:00")),
        (TEAM_ROSTER, "/players/0/joinedOn", json!("20261114")),
        (TEAM_ROSTER, "/players/0/joinedOn", json!("2026-W46-6")),
        (TEAM_ROSTER, "/players/0/birthDate", json!("14/03/2014")),
    ];
    let body_for = |path: &str, pointer: &str, value: &Value| {
        with(
            &fixture(if path == MATCH_SHEET { "match-sheet.json" } else { "team-roster.json" }),
            pointer,
            value.clone(),
        )
    };
    for (path, pointer, value) in accepted {
        let answer = post(&service.router, path, &body_for(path, pointer, &value)).await;
        assert_eq!(answer.status, StatusCode::OK, "{pointer} = {value}");
    }
    for (path, pointer, value) in refused {
        let answer = post(&service.router, path, &body_for(path, pointer, &value)).await;
        assert_eq!(answer.status, StatusCode::BAD_REQUEST, "{pointer} = {value}");
        assert_eq!(problem(&answer)["code"], "VALIDATION_FAILED", "{pointer} = {value}");
    }
}

#[tokio::test]
async fn malformed_json_is_400() {
    let service = service();
    let malformed = b"{\"locale\": \"Sari".to_vec();
    let answer =
        post_raw(&service.router, MATCH_SHEET, Some(&core_token()), "application/json; charset=utf-8", malformed).await;
    assert_eq!(answer.status, StatusCode::BAD_REQUEST);
    assert_eq!(problem(&answer)["violations"][0]["code"], "MALFORMED_JSON");
    assert_no_request_values(&answer.body, "the answer");
}

#[tokio::test]
async fn unknown_routes_and_methods_are_problems() {
    let service = service();
    let answer = call(&service.router, Method::GET, "/internal/pdf/anything", &[], vec![]).await;
    assert_eq!(answer.status, StatusCode::NOT_FOUND);
    assert_eq!(problem(&answer)["code"], "NOT_FOUND");
    let answer = call(&service.router, Method::GET, MATCH_SHEET, &[], vec![]).await;
    assert_eq!(answer.status, StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(problem(&answer)["code"], "METHOD_NOT_ALLOWED");
}

#[tokio::test]
async fn health_and_metrics_answer_without_a_token() {
    let service = service();
    for path in ["/q/health", "/q/health/live", "/q/health/ready", "/q/health/started"] {
        let answer = call(&service.router, Method::GET, path, &[], vec![]).await;
        assert_eq!(answer.status, StatusCode::OK, "{path}");
        assert_eq!(answer.json()["status"], "UP");
    }
    let _ = call(&service.router, Method::POST, TEAM_ROSTER, &[], vec![]).await;
    let metrics = call(&service.router, Method::GET, "/q/metrics", &[], vec![]).await;
    let text = String::from_utf8(metrics.body).unwrap();
    assert!(text.contains("hoops_authz_denied_total{kind=\"unauthenticated\"} 1"), "{text}");
    assert!(text.contains("hoops_authz_denied_total{kind=\"realm_role\"} 0"), "{text}");
}
