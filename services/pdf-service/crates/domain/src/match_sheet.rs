//! The match sheet / box score (decision 90): what game-service holds for a match (`Match`, `BoxScore` of
//! `game.yaml`) as the caller has already filtered it for the user, printed with the academy's name and zone.

use jiff::Timestamp;

use crate::academy::Academy;
use crate::document::{Block, Column, Fact, PrintDocument, Row, RowStyle, Table};
use crate::error::{Checks, SheetError};
use crate::file_name;
use crate::labels::{Label, Locale};
use crate::text;

/// Player lines per sheet (a match roster holds at most 30 players, `ReplaceMatchRosterRequest`).
pub const MAX_PLAYERS: usize = 30;
/// Period scores per sheet (periods 1..=12, overtimes included, `MatchEventBase.period`).
pub const MAX_PERIODS: usize = 12;
/// Team and opponent names (`CreateMatchRequest.opponentName`), player display names (not the academy: `academy::MAX_DISPLAY_NAME`).
pub const MAX_DISPLAY_NAME: usize = 120;
/// `CreateMatchRequest.venue`.
pub const MAX_VENUE: usize = 200;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HomeAway {
    Home,
    Away,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MatchStatus {
    Scheduled,
    Live,
    Finished,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Score {
    pub team: u32,
    pub opponent: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PeriodScore {
    pub period: u32,
    pub team: u32,
    pub opponent: u32,
}

/// Counting statistics, as game's `StatLine` (fg1 = free throws).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct StatLine {
    pub points: u32,
    pub fg1_made: u32,
    pub fg1_attempted: u32,
    pub fg2_made: u32,
    pub fg2_attempted: u32,
    pub fg3_made: u32,
    pub fg3_attempted: u32,
    pub assists: u32,
    pub offensive_rebounds: u32,
    pub defensive_rebounds: u32,
    pub turnovers: u32,
    pub steals: u32,
    pub blocks: u32,
    pub personal_fouls: u32,
    pub technical_fouls: u32,
    pub unsportsmanlike_fouls: u32,
    pub seconds_played: u32,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlayerLine {
    pub display_name: String,
    pub jersey_number: Option<String>,
    pub was_starter: bool,
    pub stats: StatLine,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MatchSheet {
    pub locale: Locale,
    pub academy: Academy,
    pub team_name: String,
    pub opponent_name: String,
    pub home_away: HomeAway,
    pub scheduled_at: Timestamp,
    pub venue: Option<String>,
    pub status: MatchStatus,
    pub period_count: u32,
    pub period_minutes: u32,
    pub score: Score,
    pub period_scores: Vec<PeriodScore>,
    pub team_totals: StatLine,
    pub players: Vec<PlayerLine>,
}

impl MatchSheet {
    /// The sheet's rules beyond the JSON types: limits (422) first, then field rules (400).
    pub fn check(&self) -> Result<(), SheetError> {
        let mut checks = Checks::default();
        checks.rows("players", self.players.len(), MAX_PLAYERS);
        checks.rows("periodScores", self.period_scores.len(), MAX_PERIODS);
        self.academy.check(&mut checks);
        checks.add(text::required("match.teamName", &self.team_name, MAX_DISPLAY_NAME));
        checks.add(text::required("match.opponentName", &self.opponent_name, MAX_DISPLAY_NAME));
        checks.add(text::optional("match.venue", self.venue.as_deref(), MAX_VENUE));
        checks.add(text::within("match.periodCount", self.period_count, 1, 8));
        checks.add(text::within("match.periodMinutes", self.period_minutes, 1, 60));
        for (i, period) in self.period_scores.iter().enumerate() {
            checks.add(text::within(&format!("periodScores[{i}].period"), period.period, 1, 12));
        }
        for (i, player) in self.players.iter().enumerate() {
            checks.add(text::required(&format!("players[{i}].displayName"), &player.display_name, MAX_DISPLAY_NAME));
            checks.add(text::jersey(&format!("players[{i}].jerseyNumber"), player.jersey_number.as_deref()));
        }
        checks.finish()
    }

    /// The sheet as printed on `printed_at` (the footer's date, in the academy's zone).
    pub fn document(&self, printed_at: Timestamp) -> PrintDocument {
        let t = |label| self.locale.text(label);
        PrintDocument::new(
            self.locale,
            &self.academy,
            Label::MatchSheetTitle,
            vec![
                Block::Headline(format!(
                    "{} {} – {} {}",
                    self.team_name, self.score.team, self.score.opponent, self.opponent_name
                )),
                Block::Facts(self.facts()),
                Block::Table(self.periods()),
                Block::Table(self.box_score()),
                Block::Note(t(Label::StarterNote).to_owned()),
            ],
            printed_at,
        )
    }

    /// `hoops-<academy>-match-sheet-<team>-<opponent>-<yyyyMMdd>.pdf`, today in the academy's zone.
    pub fn file_name(&self, printed_at: Timestamp) -> String {
        file_name::pdf(
            &self.academy.name,
            self.academy.day(printed_at),
            &["match-sheet", &self.team_name, &self.opponent_name],
        )
    }

    fn facts(&self) -> Vec<Fact> {
        let t = |label| self.locale.text(label);
        let side = t(match self.home_away {
            HomeAway::Home => Label::Home,
            HomeAway::Away => Label::Away,
        });
        let status = t(match self.status {
            MatchStatus::Scheduled => Label::Scheduled,
            MatchStatus::Live => Label::Live,
            MatchStatus::Finished => Label::Finished,
            MatchStatus::Cancelled => Label::Cancelled,
        });
        let (date, time) = self.academy.date_and_time(self.scheduled_at);
        let mut facts = vec![
            Fact::new(t(Label::Team), format!("{} ({side})", self.team_name)),
            Fact::new(t(Label::Opponent), self.opponent_name.clone()),
            Fact::new(t(Label::Date), date),
            Fact::new(t(Label::Time), time),
            Fact::new(t(Label::TimeZone), self.academy.zone_id()),
        ];
        facts.extend(self.venue.iter().map(|venue| Fact::new(t(Label::Venue), venue.clone())));
        facts.push(Fact::new(t(Label::Status), status));
        facts.push(Fact::new(t(Label::Periods), format!("{} × {} min", self.period_count, self.period_minutes)));
        facts
    }

    fn periods(&self) -> Table {
        let t = |label| self.locale.text(label);
        let mut periods = self.period_scores.clone();
        periods.sort_by_key(|p| p.period);
        let mut columns = vec![Column::left(t(Label::Team), 6)];
        columns.extend(periods.iter().map(|p| Column::right(&self.period_label(p.period), 1)));
        columns.push(Column::right(t(Label::Total), 1));
        let side = |name: &str, score: fn(&PeriodScore) -> u32, total: u32| {
            let mut cells = vec![name.to_owned()];
            cells.extend(periods.iter().map(|p| score(p).to_string()));
            cells.push(total.to_string());
            Row::new(RowStyle::Normal, cells)
        };
        Table {
            heading: t(Label::PeriodsHeading).to_owned(),
            columns,
            rows: vec![
                side(&self.team_name, |p| p.team, self.score.team),
                side(&self.opponent_name, |p| p.opponent, self.score.opponent),
            ],
            empty: String::new(),
        }
    }

    fn period_label(&self, period: u32) -> String {
        if period <= self.period_count {
            period.to_string()
        } else {
            format!("{}{}", self.locale.text(Label::OvertimeShort), period - self.period_count)
        }
    }

    fn box_score(&self) -> Table {
        let t = |label| self.locale.text(label);
        let mut columns = vec![Column::right(t(Label::Number), 2), Column::left(t(Label::Player), 10)];
        columns.extend(
            [
                (Label::Minutes, 3),
                (Label::Points, 2),
                (Label::FreeThrows, 3),
                (Label::TwoPointers, 3),
                (Label::ThreePointers, 3),
                (Label::OffensiveRebounds, 2),
                (Label::DefensiveRebounds, 2),
                (Label::Rebounds, 2),
                (Label::Assists, 2),
                (Label::Steals, 2),
                (Label::Blocks, 2),
                (Label::Turnovers, 2),
                (Label::Fouls, 2),
            ]
            .map(|(label, weight)| Column::right(t(label), weight)),
        );
        let mut rows: Vec<Row> = self
            .players
            .iter()
            .map(|p| {
                let name = if p.was_starter { format!("{} *", p.display_name) } else { p.display_name.clone() };
                stat_row(RowStyle::Normal, p.jersey_number.clone().unwrap_or_default(), name, &p.stats)
            })
            .collect();
        rows.push(stat_row(RowStyle::Strong, String::new(), t(Label::TeamTotals).to_owned(), &self.team_totals));
        Table { heading: t(Label::BoxScoreHeading).to_owned(), columns, rows, empty: t(Label::NoPlayers).to_owned() }
    }
}

fn stat_row(style: RowStyle, number: String, name: String, s: &StatLine) -> Row {
    let made = |made: u32, attempted: u32| format!("{made}/{attempted}");
    let mut cells = vec![
        number,
        name,
        format!("{}:{:02}", s.seconds_played / 60, s.seconds_played % 60),
        s.points.to_string(),
        made(s.fg1_made, s.fg1_attempted),
        made(s.fg2_made, s.fg2_attempted),
        made(s.fg3_made, s.fg3_attempted),
    ];
    cells.extend(
        [
            s.offensive_rebounds,
            s.defensive_rebounds,
            s.offensive_rebounds + s.defensive_rebounds,
            s.assists,
            s.steals,
            s.blocks,
            s.turnovers,
            s.personal_fouls,
        ]
        .map(|n| n.to_string()),
    );
    Row::new(style, cells)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::document::Align;
    use crate::document::Orientation;
    use jiff::tz::TimeZone;

    fn line(points: u32) -> StatLine {
        StatLine {
            points,
            fg1_made: 2,
            fg1_attempted: 4,
            fg2_made: 3,
            fg2_attempted: 7,
            fg3_made: 1,
            fg3_attempted: 2,
            assists: 3,
            offensive_rebounds: 1,
            defensive_rebounds: 4,
            turnovers: 2,
            steals: 1,
            blocks: 0,
            personal_fouls: 3,
            technical_fouls: 1,
            unsportsmanlike_fouls: 0,
            seconds_played: 1234,
        }
    }

    pub(crate) fn sheet() -> MatchSheet {
        MatchSheet {
            locale: Locale::En,
            academy: Academy { name: "Hoops Sur".into(), time_zone: TimeZone::get("Europe/Madrid").unwrap() },
            team_name: "U12 Lions".into(),
            opponent_name: "Riverside".into(),
            home_away: HomeAway::Home,
            scheduled_at: "2026-11-14T09:00:00Z".parse::<Timestamp>().unwrap(),
            venue: Some("Pabellón Norte".into()),
            status: MatchStatus::Finished,
            period_count: 4,
            period_minutes: 10,
            score: Score { team: 52, opponent: 48 },
            period_scores: vec![
                PeriodScore { period: 1, team: 10, opponent: 12 },
                PeriodScore { period: 2, team: 14, opponent: 10 },
                PeriodScore { period: 3, team: 12, opponent: 12 },
                PeriodScore { period: 4, team: 10, opponent: 10 },
                PeriodScore { period: 5, team: 6, opponent: 4 },
            ],
            team_totals: line(52),
            players: vec![
                PlayerLine {
                    display_name: "Ana García".into(),
                    jersey_number: Some("7".into()),
                    was_starter: true,
                    stats: line(11),
                },
                PlayerLine {
                    display_name: "Budi Santoso".into(),
                    jersey_number: None,
                    was_starter: false,
                    stats: line(4),
                },
            ],
        }
    }

    fn printed() -> Timestamp {
        "2026-11-15T23:30:00Z".parse::<Timestamp>().unwrap()
    }

    fn table(document: &PrintDocument, index: usize) -> &Table {
        document
            .blocks
            .iter()
            .filter_map(|b| if let Block::Table(t) = b { Some(t) } else { None })
            .nth(index)
            .expect("table")
    }

    #[test]
    fn a_complete_sheet_passes() {
        assert_eq!(sheet().check(), Ok(()));
    }

    #[test]
    fn more_players_than_a_match_roster_holds_is_too_many_rows() {
        let mut s = sheet();
        s.players = vec![s.players[0].clone(); MAX_PLAYERS + 1];
        assert_eq!(s.check(), Err(SheetError::TooManyRows { field: "players".into(), max: 30 }));
        s.players.truncate(MAX_PLAYERS);
        assert_eq!(s.check(), Ok(()));
    }

    #[test]
    fn more_than_twelve_periods_is_too_many_rows() {
        let mut s = sheet();
        s.period_scores = (1..=13).map(|period| PeriodScore { period: period.min(12), team: 0, opponent: 0 }).collect();
        assert_eq!(s.check(), Err(SheetError::TooManyRows { field: "periodScores".into(), max: 12 }));
    }

    #[test]
    fn field_rules_name_every_offending_field() {
        let mut s = sheet();
        s.academy.name = String::new();
        s.team_name = "x".repeat(MAX_DISPLAY_NAME + 1);
        s.opponent_name = " ".into();
        s.venue = Some("a\nb".into());
        s.period_count = 9;
        s.period_minutes = 0;
        s.period_scores[0].period = 13;
        s.players[1].jersey_number = Some("123".into());
        s.players[0].display_name = String::new();
        let Err(SheetError::Invalid(violations)) = s.check() else { panic!("expected violations") };
        let fields: Vec<_> = violations.iter().map(|v| v.field.as_str()).collect();
        assert_eq!(
            fields,
            [
                "academy.name",
                "match.teamName",
                "match.opponentName",
                "match.venue",
                "match.periodCount",
                "match.periodMinutes",
                "periodScores[0].period",
                "players[0].displayName",
                "players[1].jerseyNumber"
            ]
        );
    }

    #[test]
    fn the_document_heads_with_the_academy_title_and_score() {
        let d = sheet().document(printed());
        assert_eq!((d.academy.as_str(), d.title.as_str()), ("Hoops Sur", "Match sheet"));
        assert_eq!(d.orientation, Orientation::Landscape);
        assert_eq!(d.blocks[0], Block::Headline("U12 Lions 52 – 48 Riverside".into()));
        assert_eq!((d.page_word.as_str(), d.of_word.as_str()), ("Page", "of"));
    }

    #[test]
    fn the_facts_give_times_in_the_academys_zone() {
        let Block::Facts(facts) = &sheet().document(printed()).blocks[1] else { panic!("facts") };
        let pairs: Vec<_> = facts.iter().map(|f| (f.label.as_str(), f.value.as_str())).collect();
        assert_eq!(
            pairs,
            [
                ("Team", "U12 Lions (Home)"),
                ("Opponent", "Riverside"),
                ("Date", "2026-11-14"),
                ("Time", "10:00"),
                ("Time zone", "Europe/Madrid"),
                ("Venue", "Pabellón Norte"),
                ("Status", "Finished"),
                ("Periods", "4 × 10 min")
            ]
        );
    }

    #[test]
    fn without_a_venue_the_fact_is_left_out_and_away_is_said() {
        let mut s = sheet();
        s.venue = None;
        s.home_away = HomeAway::Away;
        s.status = MatchStatus::Cancelled;
        s.locale = Locale::Es;
        let Block::Facts(facts) = &s.document(printed()).blocks[1] else { panic!("facts") };
        assert_eq!(facts[0], Fact::new("Equipo", "U12 Lions (Visitante)"));
        assert!(facts.iter().all(|f| f.label != "Lugar"));
        assert!(facts.contains(&Fact::new("Estado", "Cancelado")));
    }

    #[test]
    fn period_scores_are_sorted_and_overtimes_named() {
        let mut s = sheet();
        s.period_scores.reverse();
        let d = s.document(printed());
        let periods = table(&d, 0);
        assert_eq!(periods.heading, "Score by period");
        let labels: Vec<_> = periods.columns.iter().map(|c| c.label.as_str()).collect();
        assert_eq!(labels, ["Team", "1", "2", "3", "4", "OT1", "Total"]);
        assert_eq!(periods.rows[0].cells, ["U12 Lions", "10", "14", "12", "10", "6", "52"]);
        assert_eq!(periods.rows[1].cells, ["Riverside", "12", "10", "12", "10", "4", "48"]);
    }

    #[test]
    fn the_box_score_prints_each_player_and_the_team_totals() {
        let d = sheet().document(printed());
        let box_score = table(&d, 1);
        assert_eq!(box_score.heading, "Box score");
        let labels: Vec<_> = box_score.columns.iter().map(|c| c.label.as_str()).collect();
        assert_eq!(
            labels,
            ["No.", "Player", "MIN", "PTS", "FT", "2P", "3P", "OREB", "DREB", "REB", "AST", "STL", "BLK", "TO", "PF"]
        );
        assert_eq!(box_score.columns[1].align, Align::Left);
        assert_eq!(box_score.columns[2].align, Align::Right);
        assert_eq!(
            box_score.rows[0].cells,
            ["7", "Ana García *", "20:34", "11", "2/4", "3/7", "1/2", "1", "4", "5", "3", "1", "0", "2", "3"]
        );
        assert_eq!(box_score.rows[1].cells[..3], ["", "Budi Santoso", "20:34"]);
        let totals = box_score.rows.last().expect("totals");
        assert_eq!(totals.style, RowStyle::Strong);
        assert_eq!(totals.cells[..4], ["", "Team totals", "20:34", "52"]);
        assert_eq!(box_score.empty, "No players");
        assert_eq!(d.blocks.last(), Some(&Block::Note("* starter".into())));
    }

    #[test]
    fn the_footer_dates_the_print_in_the_academys_zone() {
        assert_eq!(sheet().document(printed()).footer, "Printed on 2026-11-16 00:30 (Europe/Madrid)");
    }

    #[test]
    fn every_language_prints_its_own_labels() {
        for (locale, title, totals) in
            [(Locale::Es, "Acta del partido", "Totales del equipo"), (Locale::Id, "Lembar pertandingan", "Total tim")]
        {
            let d = MatchSheet { locale, ..sheet() }.document(printed());
            assert_eq!(d.title, title);
            assert_eq!(d.locale, locale);
            assert!(d.texts().contains(&totals), "{locale:?}");
        }
    }

    #[test]
    fn the_file_name_names_both_teams_and_the_academys_day() {
        assert_eq!(sheet().file_name(printed()), "hoops-hoops-sur-match-sheet-u12-lions-riverside-20261116.pdf");
    }
}
