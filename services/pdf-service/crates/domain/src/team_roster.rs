//! The team roster (decision 90): what core's roster export holds (ADR-0048: the players of the team's open
//! assignments with their natural category, eligibility, jersey, contact and active guardians, then the staff), as
//! core has already authorised and loaded it, printed with the academy's name and zone.

use chrono::{DateTime, NaiveDate, Utc};

use crate::academy::Academy;
use crate::document::{Block, Column, Fact, Orientation, PrintDocument, Row, RowStyle, Table};
use crate::error::{Checks, SheetError};
use crate::file_name;
use crate::labels::{Label, Locale};
use crate::text;

/// Players per sheet.
pub const MAX_PLAYERS: usize = 60;
/// Staff members per sheet.
pub const MAX_STAFF: usize = 20;
/// Active guardians per player.
pub const MAX_GUARDIANS: usize = 4;
/// Person names (`core.yaml`: given and family name, 1..80).
pub const MAX_PERSON_NAME: usize = 80;
/// Team name, season name and category.
pub const MAX_TEAM_TEXT: usize = 120;
pub const MAX_EMAIL: usize = 254;
pub const MAX_PHONE: usize = 32;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Gender {
    Male,
    Female,
}

/// The assignment's stored state, as the roster screen and the CSV export show it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Eligibility {
    Eligible,
    PlayUp,
    Ineligible,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StaffRole {
    Coach,
    AssistantCoach,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TeamInfo {
    pub name: String,
    pub season: Option<String>,
    pub category: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Guardian {
    pub given_name: String,
    pub family_name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RosterPlayer {
    pub given_name: String,
    pub family_name: String,
    pub birth_date: Option<NaiveDate>,
    pub gender: Option<Gender>,
    pub age_category: Option<String>,
    pub eligibility: Eligibility,
    pub play_up_levels: u32,
    pub jersey_number: Option<String>,
    pub joined_on: NaiveDate,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub guardians: Vec<Guardian>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StaffMember {
    pub role: StaffRole,
    pub given_name: String,
    pub family_name: String,
    pub since: NaiveDate,
    pub email: Option<String>,
    pub phone: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TeamRoster {
    pub locale: Locale,
    pub academy: Academy,
    pub team: TeamInfo,
    pub players: Vec<RosterPlayer>,
    pub staff: Vec<StaffMember>,
}

impl TeamRoster {
    /// The sheet's rules beyond the JSON types: limits (422) first, then field rules (400).
    pub fn check(&self) -> Result<(), SheetError> {
        todo!()
    }

    /// The sheet as printed on `printed_at` (the footer's date, in the academy's zone).
    pub fn document(&self, printed_at: DateTime<Utc>) -> PrintDocument {
        todo!()
    }

    /// `hoops-<academy>-roster-<team>-<yyyyMMdd>.pdf`, today in the academy's zone (as core's CSV, with `.pdf`).
    pub fn file_name(&self, printed_at: DateTime<Utc>) -> String {
        todo!()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn day(m: u32, d: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, m, d).unwrap()
    }

    fn guardian(name: &str) -> Guardian {
        Guardian { given_name: name.into(), family_name: "Santoso".into(), email: Some("wali@example.test".into()), phone: Some("+62 811 000".into()) }
    }

    fn player() -> RosterPlayer {
        RosterPlayer {
            given_name: "Budi".into(),
            family_name: "Santoso".into(),
            birth_date: Some(NaiveDate::from_ymd_opt(2014, 3, 9).unwrap()),
            gender: Some(Gender::Male),
            age_category: Some("U12".into()),
            eligibility: Eligibility::PlayUp,
            play_up_levels: 1,
            jersey_number: Some("07".into()),
            joined_on: day(9, 1),
            email: None,
            phone: Some("+62 812 345".into()),
            guardians: vec![guardian("Sri"), guardian("Agus")],
        }
    }

    pub(crate) fn roster() -> TeamRoster {
        TeamRoster {
            locale: Locale::Id,
            academy: Academy { name: "Garuda Hoops".into(), time_zone: chrono_tz::Asia::Jakarta },
            team: TeamInfo { name: "U12 Elang".into(), season: Some("2026/27".into()), category: Some("U12".into()) },
            players: vec![player()],
            staff: vec![StaffMember {
                role: StaffRole::AssistantCoach,
                given_name: "Dewi".into(),
                family_name: "Lestari".into(),
                since: day(8, 15),
                email: Some("dewi@example.test".into()),
                phone: None,
            }],
        }
    }

    fn printed() -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 11, 15, 18, 0, 0).unwrap()
    }

    fn tables(d: &PrintDocument) -> Vec<&Table> {
        d.blocks.iter().filter_map(|b| if let Block::Table(t) = b { Some(t) } else { None }).collect()
    }

    #[test]
    fn a_complete_roster_passes() {
        assert_eq!(roster().check(), Ok(()));
    }

    #[test]
    fn the_limits_are_too_many_rows() {
        let mut r = roster();
        r.players = vec![player(); MAX_PLAYERS + 1];
        assert_eq!(r.check(), Err(SheetError::TooManyRows { field: "players".into(), max: 60 }));

        let mut r = roster();
        r.staff = vec![r.staff[0].clone(); MAX_STAFF + 1];
        assert_eq!(r.check(), Err(SheetError::TooManyRows { field: "staff".into(), max: 20 }));

        let mut r = roster();
        r.players[0].guardians = vec![guardian("G"); MAX_GUARDIANS + 1];
        assert_eq!(r.check(), Err(SheetError::TooManyRows { field: "players[0].guardians".into(), max: 4 }));

        let mut r = roster();
        r.players = vec![player(); MAX_PLAYERS];
        r.staff = vec![r.staff[0].clone(); MAX_STAFF];
        assert_eq!(r.check(), Ok(()));
    }

    #[test]
    fn field_rules_name_every_offending_field() {
        let mut r = roster();
        r.academy.name = " ".into();
        r.team.name = String::new();
        r.team.season = Some("x".repeat(MAX_TEAM_TEXT + 1));
        r.team.category = Some("\t".into());
        r.players[0].given_name = String::new();
        r.players[0].family_name = "y".repeat(MAX_PERSON_NAME + 1);
        r.players[0].age_category = Some("a\u{0}".into());
        r.players[0].jersey_number = Some("x".into());
        r.players[0].email = Some("e".repeat(MAX_EMAIL + 1));
        r.players[0].phone = Some("9".repeat(MAX_PHONE + 1));
        r.players[0].play_up_levels = 21;
        r.players[0].guardians[1].given_name = String::new();
        r.players[0].guardians[1].phone = Some("\n".into());
        r.staff[0].family_name = String::new();
        r.staff[0].email = Some("\r".into());
        let Err(SheetError::Invalid(violations)) = r.check() else { panic!("expected violations") };
        let fields: Vec<_> = violations.iter().map(|v| v.field.as_str()).collect();
        assert_eq!(
            fields,
            [
                "academy.name",
                "team.name",
                "team.season",
                "team.category",
                "players[0].givenName",
                "players[0].familyName",
                "players[0].ageCategory",
                "players[0].jerseyNumber",
                "players[0].email",
                "players[0].phone",
                "players[0].playUpLevels",
                "players[0].guardians[1].givenName",
                "players[0].guardians[1].phone",
                "staff[0].familyName",
                "staff[0].email"
            ]
        );
    }

    #[test]
    fn the_document_heads_with_the_team() {
        let d = roster().document(printed());
        assert_eq!((d.academy.as_str(), d.title.as_str()), ("Garuda Hoops", "Daftar tim"));
        assert_eq!(d.orientation, Orientation::Landscape);
        assert_eq!(
            d.blocks[0],
            Block::Facts(vec![Fact::new("Tim", "U12 Elang"), Fact::new("Musim", "2026/27"), Fact::new("Kategori", "U12")])
        );
        assert_eq!(d.footer, "Dicetak pada 2026-11-16 01:00 (Asia/Jakarta)");
        assert_eq!((d.page_word.as_str(), d.of_word.as_str()), ("Halaman", "dari"));
    }

    #[test]
    fn a_team_without_season_or_category_prints_only_its_name() {
        let mut r = roster();
        r.team.season = None;
        r.team.category = None;
        assert_eq!(r.document(printed()).blocks[0], Block::Facts(vec![Fact::new("Tim", "U12 Elang")]));
    }

    #[test]
    fn each_player_is_a_row_followed_by_their_guardians() {
        let d = roster().document(printed());
        let players = tables(&d)[0];
        assert_eq!(players.heading, "Pemain");
        let labels: Vec<_> = players.columns.iter().map(|c| c.label.as_str()).collect();
        assert_eq!(
            labels,
            ["Nomor", "Nama", "Tanggal lahir", "Jenis kelamin", "Kategori usia", "Kelayakan", "Bergabung", "Email", "Telepon"]
        );
        assert_eq!(
            players.rows[0],
            Row::new(
                RowStyle::Normal,
                vec![
                    "07".into(),
                    "Santoso, Budi".into(),
                    "2014-03-09".into(),
                    "Laki-laki".into(),
                    "U12".into(),
                    "Naik kategori (+1)".into(),
                    "2026-09-01".into(),
                    String::new(),
                    "+62 812 345".into()
                ]
            )
        );
        assert_eq!(players.rows[1].style, RowStyle::Detail);
        assert_eq!(
            players.rows[1].cells,
            ["", "Wali: Santoso, Sri", "", "", "", "", "", "wali@example.test", "+62 811 000"]
        );
        assert_eq!(players.rows.len(), 3);
        assert_eq!(players.empty, "Tidak ada pemain");
    }

    #[test]
    fn eligibility_gender_and_missing_values_print_as_labels_or_blanks() {
        let mut r = roster();
        r.locale = Locale::En;
        r.players[0].eligibility = Eligibility::Ineligible;
        r.players[0].gender = Some(Gender::Female);
        r.players[0].birth_date = None;
        r.players[0].age_category = None;
        r.players[0].jersey_number = None;
        r.players[0].guardians.clear();
        r.players.push(RosterPlayer { eligibility: Eligibility::Eligible, gender: None, ..player() });
        let d = r.document(printed());
        let rows = &tables(&d)[0].rows;
        assert_eq!(rows[0].cells[..6], ["", "Santoso, Budi", "", "Female", "", "Not eligible"]);
        assert_eq!(rows[1].cells[3..6], ["", "U12", "Eligible"]);
    }

    #[test]
    fn the_staff_follows_in_its_own_table() {
        let mut r = roster();
        r.locale = Locale::Es;
        r.staff.push(StaffMember { role: StaffRole::Coach, ..r.staff[0].clone() });
        let d = r.document(printed());
        let staff = tables(&d)[1];
        assert_eq!(staff.heading, "Cuerpo técnico");
        let labels: Vec<_> = staff.columns.iter().map(|c| c.label.as_str()).collect();
        assert_eq!(labels, ["Rol", "Nombre", "Desde", "Correo electrónico", "Teléfono"]);
        assert_eq!(staff.rows[0].cells, ["Entrenador asistente", "Lestari, Dewi", "2026-08-15", "dewi@example.test", ""]);
        assert_eq!(staff.rows[1].cells[0], "Entrenador");
        assert_eq!(staff.empty, "—");
    }

    #[test]
    fn the_file_name_names_the_team_and_the_academys_day() {
        assert_eq!(roster().file_name(printed()), "hoops-garuda-hoops-roster-u12-elang-20261116.pdf");
    }
}
