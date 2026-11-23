//! Shared by the adapters' integration tests: sample sheets, the text of a PDF, the contract.
#![allow(dead_code, clippy::unwrap_used, clippy::expect_used)] // each test binary uses a part; tests fail loudly

use jiff::Timestamp;
use jiff::civil::date;
use jiff::tz::TimeZone;
use pdf_domain::{
    Academy, Eligibility, Gender, Guardian, HomeAway, Locale, MatchSheet, MatchStatus, PeriodScore, PlayerLine,
    RosterPlayer, Score, StaffMember, StaffRole, StatLine, TeamInfo, TeamRoster,
};

pub use pdf_adapters::http::{MATCH_SHEET, TEAM_ROSTER};

pub fn printed_at() -> Timestamp {
    "2026-11-15T09:41:00Z".parse::<Timestamp>().unwrap()
}

fn stats(points: u32) -> StatLine {
    StatLine { points, fg2_made: points / 2, fg2_attempted: points, seconds_played: 600, ..StatLine::default() }
}

pub fn match_sheet(locale: Locale) -> MatchSheet {
    MatchSheet {
        locale,
        academy: Academy { name: "Academia Ñandú".into(), time_zone: TimeZone::get("Europe/Madrid").unwrap() },
        team_name: "U12 Leones".into(),
        opponent_name: "CB Halcones".into(),
        home_away: HomeAway::Home,
        scheduled_at: "2026-11-14T09:00:00Z".parse::<Timestamp>().unwrap(),
        venue: Some("Pabellón Norte".into()),
        status: MatchStatus::Finished,
        period_count: 4,
        period_minutes: 10,
        score: Score { team: 52, opponent: 48 },
        period_scores: (1..=4).map(|period| PeriodScore { period, team: 13, opponent: 12 }).collect(),
        team_totals: stats(52),
        players: vec![
            PlayerLine {
                display_name: "Lucía Martínez".into(),
                jersey_number: Some("7".into()),
                was_starter: true,
                stats: stats(18),
            },
            PlayerLine {
                display_name: "Budi Santoso".into(),
                jersey_number: None,
                was_starter: false,
                stats: stats(6),
            },
        ],
    }
}

pub fn player(given: &str, guardians: usize) -> RosterPlayer {
    RosterPlayer {
        given_name: given.into(),
        family_name: "Santoso".into(),
        birth_date: Some(date(2014, 3, 9)),
        gender: Some(Gender::Female),
        age_category: Some("U12".into()),
        eligibility: Eligibility::Eligible,
        play_up_levels: 0,
        jersey_number: Some("10".into()),
        joined_on: date(2026, 9, 1),
        email: Some("pemain@example.test".into()),
        phone: None,
        guardians: (0..guardians)
            .map(|i| Guardian {
                given_name: format!("Wali{i}"),
                family_name: "Santoso".into(),
                email: None,
                phone: Some("+62 811 000".into()),
            })
            .collect(),
    }
}

pub fn team_roster(locale: Locale) -> TeamRoster {
    TeamRoster {
        locale,
        academy: Academy { name: "Garuda Hoops".into(), time_zone: TimeZone::get("Asia/Jakarta").unwrap() },
        team: TeamInfo { name: "U12 Elang".into(), season: Some("2026/27".into()), category: Some("U12".into()) },
        players: vec![player("Sari", 1)],
        staff: vec![StaffMember {
            role: StaffRole::Coach,
            given_name: "Dewi".into(),
            family_name: "Lestari".into(),
            since: date(2026, 8, 15),
            email: None,
            phone: None,
        }],
    }
}

/// The text of every page, pages joined by a form feed.
pub fn pdf_text(pdf: &[u8]) -> String {
    let document = lopdf::Document::load_mem(pdf).expect("a readable PDF");
    let pages: Vec<u32> = document.get_pages().keys().copied().collect();
    pages.iter().map(|page| document.extract_text(&[*page]).expect("text")).collect::<Vec<_>>().join("\u{c}")
}

pub fn page_count(pdf: &[u8]) -> usize {
    lopdf::Document::load_mem(pdf).expect("a readable PDF").get_pages().len()
}

pub mod app;
pub mod contract;

/// `body` with `value` at the JSON pointer (the last key is inserted or replaced).
pub fn with(body: &serde_json::Value, pointer: &str, value: serde_json::Value) -> serde_json::Value {
    let mut body = body.clone();
    let (parent, key) = pointer.rsplit_once('/').unwrap();
    body.pointer_mut(parent).unwrap().as_object_mut().unwrap().insert(key.to_owned(), value);
    body
}

/// `body` without the member at the JSON pointer.
pub fn without(body: &serde_json::Value, pointer: &str) -> serde_json::Value {
    let mut body = body.clone();
    let (parent, key) = pointer.rsplit_once('/').unwrap();
    body.pointer_mut(parent).unwrap().as_object_mut().unwrap().remove(key);
    body
}

/// Members of the fixtures that name a person, a contact or an academy (the values of the privacy guard, P-11).
const PERSONAL: [&str; 6] = ["givenName", "familyName", "displayName", "email", "phone", "name"];

fn personal_values(value: &serde_json::Value, key: &str, out: &mut Vec<String>) {
    match value {
        serde_json::Value::String(text) if PERSONAL.contains(&key) => {
            out.push(text.clone());
            out.extend(text.split_whitespace().filter(|word| word.chars().count() >= 4).map(str::to_owned));
        }
        serde_json::Value::Array(items) => items.iter().for_each(|item| personal_values(item, key, out)),
        serde_json::Value::Object(members) => {
            members.iter().for_each(|(name, member)| personal_values(member, name, out));
        }
        _ => {}
    }
}

/// None of the personal values of the fixtures (names, contacts, academy names; read from the fixtures themselves)
/// appears in `bytes`; `what` names where they were looked for.
pub fn assert_no_request_values(bytes: &[u8], what: &str) {
    let mut values = Vec::new();
    for name in ["match-sheet.json", "team-roster.json"] {
        personal_values(&app::fixture(name), "", &mut values);
    }
    assert!(values.len() > 20, "the fixtures name people: {values:?}");
    let text = String::from_utf8_lossy(bytes);
    for value in values {
        assert!(!text.contains(&value), "{value:?} leaked into {what}: {text}");
    }
}
