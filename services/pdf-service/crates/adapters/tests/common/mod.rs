//! Shared by the adapters' integration tests: sample sheets, the text of a PDF, the contract.
#![allow(dead_code)] // each test binary uses a part

use chrono::{DateTime, NaiveDate, TimeZone, Utc};
use pdf_domain::{
    Academy, Eligibility, Gender, Guardian, HomeAway, Locale, MatchSheet, MatchStatus, PeriodScore, PlayerLine,
    RosterPlayer, Score, StaffMember, StaffRole, StatLine, TeamInfo, TeamRoster,
};

pub fn printed_at() -> DateTime<Utc> {
    Utc.with_ymd_and_hms(2026, 11, 15, 9, 41, 0).unwrap()
}

fn stats(points: u32) -> StatLine {
    StatLine { points, fg2_made: points / 2, fg2_attempted: points, seconds_played: 600, ..StatLine::default() }
}

pub fn match_sheet(locale: Locale) -> MatchSheet {
    MatchSheet {
        locale,
        academy: Academy { name: "Academia Ñandú".into(), time_zone: chrono_tz::Europe::Madrid },
        team_name: "U12 Leones".into(),
        opponent_name: "CB Halcones".into(),
        home_away: HomeAway::Home,
        scheduled_at: Utc.with_ymd_and_hms(2026, 11, 14, 9, 0, 0).unwrap(),
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
        birth_date: NaiveDate::from_ymd_opt(2014, 3, 9),
        gender: Some(Gender::Female),
        age_category: Some("U12".into()),
        eligibility: Eligibility::Eligible,
        play_up_levels: 0,
        jersey_number: Some("10".into()),
        joined_on: NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
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
        academy: Academy { name: "Garuda Hoops".into(), time_zone: chrono_tz::Asia::Jakarta },
        team: TeamInfo { name: "U12 Elang".into(), season: Some("2026/27".into()), category: Some("U12".into()) },
        players: vec![player("Sari", 1)],
        staff: vec![StaffMember {
            role: StaffRole::Coach,
            given_name: "Dewi".into(),
            family_name: "Lestari".into(),
            since: NaiveDate::from_ymd_opt(2026, 8, 15).unwrap(),
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
