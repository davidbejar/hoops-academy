//! `pdf.yaml` is the source of truth (contract first): the requests the tests send are validated against it, every
//! answer is one the contract declares (status, media type, `Problem` body, headers), and the service refuses exactly
//! the bodies the contract refuses.

use crate::common;

use axum::http::{Method, StatusCode};
use common::app::{Answer, call, fixture, post, service};
use common::contract::{declared_response, errors, operation, yaml};
use common::{MATCH_SHEET, TEAM_ROSTER, with, without};
use pdf_domain::{academy, match_sheet as m, team_roster as r};
use serde_json::{Value, json};

fn request_schema(path: &str) -> &'static str {
    if path == MATCH_SHEET { "MatchSheetRequest" } else { "TeamRosterRequest" }
}

/// The answer is one the contract declares for the operation.
fn assert_declared(path: &str, answer: &Answer) {
    let declared = declared_response(path, answer.status.as_u16())
        .unwrap_or_else(|| panic!("{path} does not declare {}", answer.status));
    let media = answer.header("content-type");
    assert!(declared["content"].get(media).is_some(), "{path} {}: {media} is not declared", answer.status);
    if media == "application/problem+json" {
        let problems = errors("common.yaml", "Problem", &answer.json());
        assert!(problems.is_empty(), "{path} {}: {problems:?}", answer.status);
        assert_eq!(answer.json()["status"], answer.status.as_u16());
    } else {
        for header in declared["headers"].as_object().unwrap().keys() {
            assert!(!answer.header(header).is_empty(), "{path}: header {header} is declared");
        }
        assert!(answer.body.starts_with(b"%PDF-"));
    }
}

#[test]
fn the_fixtures_follow_the_contract() {
    assert_eq!(errors("pdf.yaml", "MatchSheetRequest", &fixture("match-sheet.json")), Vec::<String>::new());
    assert_eq!(errors("pdf.yaml", "TeamRosterRequest", &fixture("team-roster.json")), Vec::<String>::new());
    assert_eq!(yaml("pdf.yaml")["info"]["version"], "1.0.0");
}

#[tokio::test]
async fn every_operation_of_the_contract_is_served() {
    let service = service();
    let paths = yaml("pdf.yaml")["paths"].as_object().unwrap().keys().cloned().collect::<Vec<_>>();
    assert_eq!(paths, [MATCH_SHEET, TEAM_ROSTER]);
    for (path, body) in [(MATCH_SHEET, fixture("match-sheet.json")), (TEAM_ROSTER, fixture("team-roster.json"))] {
        assert!(operation(path)["operationId"].is_string());
        let answer = post(&service.router, path, &body).await;
        assert_eq!(answer.status, StatusCode::OK, "{path}");
        assert_declared(path, &answer);
    }
}

#[tokio::test]
async fn the_service_refuses_exactly_what_the_contract_refuses() {
    let service = service();
    let cases: Vec<(&str, Value)> = vec![
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/1/email", json!(null))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/team/season", json!(null))),
        (TEAM_ROSTER, without(&fixture("team-roster.json"), "/team/category")),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/staff", json!([]))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/locale", json!("de"))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/eligibility", json!("MAYBE"))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/playUpLevels", json!(-1))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/playUpLevels", json!(21))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/familyName", json!(""))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/givenName", json!("x".repeat(81)))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/jerseyNumber", json!("100"))),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/extra", json!(1))),
        (TEAM_ROSTER, without(&fixture("team-roster.json"), "/staff")),
        (TEAM_ROSTER, with(&fixture("team-roster.json"), "/players/0/guardians", json!(vec![guardian(); 5]))),
        (
            TEAM_ROSTER,
            with(
                &fixture("team-roster.json"),
                "/staff",
                json!(vec![fixture("team-roster.json")["staff"][0].clone(); 21]),
            ),
        ),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/match/venue", json!(null))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/players", json!([]))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/match/homeAway", json!("NEUTRAL"))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/match/periodCount", json!(9))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/match/periodMinutes", json!(0))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/match/scheduledAt", json!("yesterday"))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/periodScores/0/period", json!(13))),
        (MATCH_SHEET, with(&fixture("match-sheet.json"), "/match/opponentName", json!("y".repeat(121)))),
        (
            MATCH_SHEET,
            with(
                &fixture("match-sheet.json"),
                "/players",
                json!(vec![fixture("match-sheet.json")["players"][0].clone(); 31]),
            ),
        ),
        (
            MATCH_SHEET,
            with(
                &fixture("match-sheet.json"),
                "/periodScores",
                json!(vec![json!({"period": 1, "team": 0, "opponent": 0}); 13]),
            ),
        ),
        (MATCH_SHEET, without(&fixture("match-sheet.json"), "/teamTotals")),
    ];
    for (path, body) in cases {
        let refused_by_contract = !errors("pdf.yaml", request_schema(path), &body).is_empty();
        let answer = post(&service.router, path, &body).await;
        assert_declared(path, &answer);
        let refused_by_service = matches!(answer.status, StatusCode::BAD_REQUEST | StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(refused_by_service, refused_by_contract, "{path} {} for {body}", answer.status);
        if answer.status == StatusCode::UNPROCESSABLE_ENTITY {
            assert_eq!(answer.json()["code"], "TOO_MANY_ROWS");
        }
    }
}

#[tokio::test]
async fn every_refusal_is_a_declared_problem() {
    let service = service();
    let no_token =
        call(&service.router, Method::POST, MATCH_SHEET, &[("content-type", "application/json")], b"{}".to_vec()).await;
    assert_declared(MATCH_SHEET, &no_token);
    let mut large = fixture("team-roster.json");
    large["team"]["name"] = json!("x".repeat(300 * 1024));
    assert_declared(TEAM_ROSTER, &post(&service.router, TEAM_ROSTER, &large).await);
}

#[test]
fn the_contracts_limits_are_the_domains() {
    let schemas = &yaml("pdf.yaml")["components"]["schemas"];
    let max_items = |schema: &str, list: &str| schemas[schema]["properties"][list]["maxItems"].as_u64().unwrap();
    let max_length = |schema: &str, field: &str| schemas[schema]["properties"][field]["maxLength"].as_u64().unwrap();
    assert_eq!(max_items("MatchSheetRequest", "players"), m::MAX_PLAYERS as u64);
    assert_eq!(max_items("MatchSheetRequest", "periodScores"), m::MAX_PERIODS as u64);
    assert_eq!(max_items("TeamRosterRequest", "players"), r::MAX_PLAYERS as u64);
    assert_eq!(max_items("TeamRosterRequest", "staff"), r::MAX_STAFF as u64);
    assert_eq!(max_items("RosterPlayer", "guardians"), r::MAX_GUARDIANS as u64);
    assert_eq!(max_length("Academy", "name"), academy::MAX_NAME as u64);
    assert_eq!(max_length("MatchInfo", "teamName"), m::MAX_NAME as u64);
    assert_eq!(max_length("MatchInfo", "venue"), m::MAX_VENUE as u64);
    assert_eq!(max_length("RosterPlayer", "givenName"), r::MAX_PERSON_NAME as u64);
    assert_eq!(max_length("RosterPlayer", "email"), r::MAX_EMAIL as u64);
    assert_eq!(max_length("RosterPlayer", "phone"), r::MAX_PHONE as u64);
    assert_eq!(max_length("RosterTeam", "name"), r::MAX_TEAM_TEXT as u64);
}

fn guardian() -> Value {
    json!({"givenName": "G", "familyName": "H"})
}
