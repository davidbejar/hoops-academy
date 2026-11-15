//! The request bodies of `pdf.yaml` (strict: unknown properties are refused, as the contract's
//! `additionalProperties: false`) and their mapping to the domain. A body that does not parse is a 400 whose
//! violations name the path of the offending property, never its value (P-11).

use chrono::{DateTime, NaiveDate, Utc};
use pdf_domain::{
    Academy, Eligibility, Gender, Guardian, HomeAway, Locale, MatchSheet, MatchStatus, PeriodScore, PlayerLine,
    RosterPlayer, Score, StaffMember, StaffRole, StatLine, TeamInfo, TeamRoster, Violation,
};
use serde::Deserialize;
use serde::de::DeserializeOwned;

use crate::problem::{Problem, ProblemViolation};

/// Parses `bytes` as `T`, or the 400 Problem that names where it went wrong.
pub fn parse<T: DeserializeOwned>(bytes: &[u8]) -> Result<T, Box<Problem>> {
    let mut deserializer = serde_json::Deserializer::from_slice(bytes);
    let parsed: T = serde_path_to_error::deserialize(&mut deserializer).map_err(|error| {
        let path = error.path().to_string();
        let path = if path == "." { String::new() } else { path };
        Box::new(Problem::validation(vec![parse_violation(&path, error.inner())]))
    })?;
    deserializer.end().map_err(|error| Box::new(Problem::validation(vec![parse_violation("", &error)])))?;
    Ok(parsed)
}

/// Field and code of a parse error. serde's message quotes the offending value, so only the property names it
/// reports for a missing property are taken from it; the message is the contract's, never serde's.
fn parse_violation(path: &str, error: &serde_json::Error) -> ProblemViolation {
    let text = error.to_string();
    let violation = |field: String, code: &str, message: &str| ProblemViolation {
        field,
        code: code.to_owned(),
        message: message.to_owned(),
    };
    if error.is_syntax() || error.is_eof() {
        return violation(String::new(), "MALFORMED_JSON", "is not a JSON document");
    }
    if let Some(name) = text.strip_prefix("missing field `").and_then(|rest| rest.split('`').next()) {
        let field = if path.is_empty() { name.to_owned() } else { format!("{path}.{name}") };
        return violation(field, "REQUIRED", "is required");
    }
    if text.starts_with("unknown field `") {
        return violation(path.to_owned(), "UNKNOWN_PROPERTY", "has a property the contract does not declare");
    }
    violation(path.to_owned(), "INVALID", "does not match the contract's type, format or enum")
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LocaleDto {
    Es,
    En,
    Id,
}

impl From<LocaleDto> for Locale {
    fn from(locale: LocaleDto) -> Self {
        match locale {
            LocaleDto::Es => Self::Es,
            LocaleDto::En => Self::En,
            LocaleDto::Id => Self::Id,
        }
    }
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
pub struct AcademyDto {
    name: String,
    time_zone: String,
}

impl AcademyDto {
    fn into_domain(self) -> Result<Academy, Violation> {
        Ok(Academy { name: self.name, time_zone: Academy::time_zone("academy.timeZone", &self.time_zone)? })
    }
}

// ---------------------------------------------------------------- match sheet

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
pub struct MatchSheetRequest {
    locale: LocaleDto,
    academy: AcademyDto,
    #[serde(rename = "match")]
    match_info: MatchInfoDto,
    score: ScoreDto,
    period_scores: Vec<PeriodScoreDto>,
    team_totals: StatLineDto,
    players: Vec<PlayerLineDto>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
struct MatchInfoDto {
    team_name: String,
    opponent_name: String,
    home_away: HomeAwayDto,
    scheduled_at: DateTime<Utc>,
    #[serde(default)]
    venue: Option<String>,
    status: MatchStatusDto,
    period_count: u32,
    period_minutes: u32,
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum HomeAwayDto {
    Home,
    Away,
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum MatchStatusDto {
    Scheduled,
    Live,
    Finished,
    Cancelled,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct ScoreDto {
    team: u32,
    opponent: u32,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct PeriodScoreDto {
    period: u32,
    team: u32,
    opponent: u32,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
struct StatLineDto {
    points: u32,
    fg1_made: u32,
    fg1_attempted: u32,
    fg2_made: u32,
    fg2_attempted: u32,
    fg3_made: u32,
    fg3_attempted: u32,
    assists: u32,
    offensive_rebounds: u32,
    defensive_rebounds: u32,
    turnovers: u32,
    steals: u32,
    blocks: u32,
    personal_fouls: u32,
    technical_fouls: u32,
    unsportsmanlike_fouls: u32,
    seconds_played: u32,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
struct PlayerLineDto {
    display_name: String,
    #[serde(default)]
    jersey_number: Option<String>,
    was_starter: bool,
    stats: StatLineDto,
}

impl From<StatLineDto> for StatLine {
    fn from(s: StatLineDto) -> Self {
        Self {
            points: s.points,
            fg1_made: s.fg1_made,
            fg1_attempted: s.fg1_attempted,
            fg2_made: s.fg2_made,
            fg2_attempted: s.fg2_attempted,
            fg3_made: s.fg3_made,
            fg3_attempted: s.fg3_attempted,
            assists: s.assists,
            offensive_rebounds: s.offensive_rebounds,
            defensive_rebounds: s.defensive_rebounds,
            turnovers: s.turnovers,
            steals: s.steals,
            blocks: s.blocks,
            personal_fouls: s.personal_fouls,
            technical_fouls: s.technical_fouls,
            unsportsmanlike_fouls: s.unsportsmanlike_fouls,
            seconds_played: s.seconds_played,
        }
    }
}

impl MatchSheetRequest {
    pub fn into_domain(self) -> Result<MatchSheet, Violation> {
        let m = self.match_info;
        Ok(MatchSheet {
            locale: self.locale.into(),
            academy: self.academy.into_domain()?,
            team_name: m.team_name,
            opponent_name: m.opponent_name,
            home_away: match m.home_away {
                HomeAwayDto::Home => HomeAway::Home,
                HomeAwayDto::Away => HomeAway::Away,
            },
            scheduled_at: m.scheduled_at,
            venue: m.venue,
            status: match m.status {
                MatchStatusDto::Scheduled => MatchStatus::Scheduled,
                MatchStatusDto::Live => MatchStatus::Live,
                MatchStatusDto::Finished => MatchStatus::Finished,
                MatchStatusDto::Cancelled => MatchStatus::Cancelled,
            },
            period_count: m.period_count,
            period_minutes: m.period_minutes,
            score: Score { team: self.score.team, opponent: self.score.opponent },
            period_scores: self
                .period_scores
                .into_iter()
                .map(|p| PeriodScore { period: p.period, team: p.team, opponent: p.opponent })
                .collect(),
            team_totals: self.team_totals.into(),
            players: self
                .players
                .into_iter()
                .map(|p| PlayerLine {
                    display_name: p.display_name,
                    jersey_number: p.jersey_number,
                    was_starter: p.was_starter,
                    stats: p.stats.into(),
                })
                .collect(),
        })
    }
}

// ---------------------------------------------------------------- team roster

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
pub struct TeamRosterRequest {
    locale: LocaleDto,
    academy: AcademyDto,
    team: TeamDto,
    players: Vec<RosterPlayerDto>,
    staff: Vec<StaffMemberDto>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct TeamDto {
    name: String,
    #[serde(default)]
    season: Option<String>,
    #[serde(default)]
    category: Option<String>,
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum GenderDto {
    Male,
    Female,
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum EligibilityDto {
    Eligible,
    PlayUp,
    Ineligible,
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum StaffRoleDto {
    Coach,
    AssistantCoach,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
struct RosterPlayerDto {
    given_name: String,
    family_name: String,
    #[serde(default)]
    birth_date: Option<NaiveDate>,
    #[serde(default)]
    gender: Option<GenderDto>,
    #[serde(default)]
    age_category: Option<String>,
    eligibility: EligibilityDto,
    play_up_levels: u32,
    #[serde(default)]
    jersey_number: Option<String>,
    joined_on: NaiveDate,
    #[serde(default)]
    email: Option<String>,
    #[serde(default)]
    phone: Option<String>,
    guardians: Vec<GuardianDto>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
struct GuardianDto {
    given_name: String,
    family_name: String,
    #[serde(default)]
    email: Option<String>,
    #[serde(default)]
    phone: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields, rename_all = "camelCase")]
struct StaffMemberDto {
    role: StaffRoleDto,
    given_name: String,
    family_name: String,
    since: NaiveDate,
    #[serde(default)]
    email: Option<String>,
    #[serde(default)]
    phone: Option<String>,
}

impl TeamRosterRequest {
    pub fn into_domain(self) -> Result<TeamRoster, Violation> {
        Ok(TeamRoster {
            locale: self.locale.into(),
            academy: self.academy.into_domain()?,
            team: TeamInfo { name: self.team.name, season: self.team.season, category: self.team.category },
            players: self.players.into_iter().map(RosterPlayerDto::into_domain).collect(),
            staff: self
                .staff
                .into_iter()
                .map(|s| StaffMember {
                    role: match s.role {
                        StaffRoleDto::Coach => StaffRole::Coach,
                        StaffRoleDto::AssistantCoach => StaffRole::AssistantCoach,
                    },
                    given_name: s.given_name,
                    family_name: s.family_name,
                    since: s.since,
                    email: s.email,
                    phone: s.phone,
                })
                .collect(),
        })
    }
}

impl RosterPlayerDto {
    fn into_domain(self) -> RosterPlayer {
        RosterPlayer {
            given_name: self.given_name,
            family_name: self.family_name,
            birth_date: self.birth_date,
            gender: self.gender.map(|g| match g {
                GenderDto::Male => Gender::Male,
                GenderDto::Female => Gender::Female,
            }),
            age_category: self.age_category,
            eligibility: match self.eligibility {
                EligibilityDto::Eligible => Eligibility::Eligible,
                EligibilityDto::PlayUp => Eligibility::PlayUp,
                EligibilityDto::Ineligible => Eligibility::Ineligible,
            },
            play_up_levels: self.play_up_levels,
            jersey_number: self.jersey_number,
            joined_on: self.joined_on,
            email: self.email,
            phone: self.phone,
            guardians: self
                .guardians
                .into_iter()
                .map(|g| Guardian {
                    given_name: g.given_name,
                    family_name: g.family_name,
                    email: g.email,
                    phone: g.phone,
                })
                .collect(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn violation_of(body: &str) -> ProblemViolation {
        parse::<TeamRosterRequest>(body.as_bytes()).unwrap_err().violations.remove(0)
    }

    #[test]
    fn malformed_json_names_no_field() {
        let v = violation_of("{\"locale\": ");
        assert_eq!((v.field.as_str(), v.code.as_str()), ("", "MALFORMED_JSON"));
        let v = parse::<serde_json::Value>(b"{} trailing").unwrap_err().violations.remove(0);
        assert_eq!(v.code, "MALFORMED_JSON");
    }

    #[test]
    fn a_missing_property_is_named_with_its_path() {
        let v = violation_of(r#"{"locale":"es","academy":{"name":"A"}}"#);
        assert_eq!((v.field.as_str(), v.code.as_str()), ("academy.timeZone", "REQUIRED"));
        let v = violation_of(r#"{"locale":"es"}"#);
        assert_eq!(v.field, "academy");
    }

    #[test]
    fn an_unknown_property_is_named_never_its_value() {
        let v = violation_of(r#"{"locale":"es","academy":{"name":"A","timeZone":"UTC","nickname":"Lucía"}}"#);
        assert_eq!((v.field.as_str(), v.code.as_str()), ("academy.nickname", "UNKNOWN_PROPERTY"));
        assert!(!v.message.contains("Lucía"));
    }

    #[test]
    fn a_wrong_value_names_its_path_never_the_value() {
        let v = violation_of(r#"{"locale":"fr","academy":{"name":"A","timeZone":"UTC"}}"#);
        assert_eq!((v.field.as_str(), v.code.as_str()), ("locale", "INVALID"));
        assert!(!v.message.contains("fr"));
    }
}
