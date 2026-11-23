//! The team roster (decision 90): what core's roster export holds (ADR-0048: the players of the team's open
//! assignments with their natural category, eligibility, jersey, contact and active guardians, then the staff), as
//! core has already authorised and loaded it, printed with the academy's name and zone.

use jiff::Timestamp;
use jiff::civil::Date;

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
    pub birth_date: Option<Date>,
    pub gender: Option<Gender>,
    pub age_category: Option<String>,
    pub eligibility: Eligibility,
    pub play_up_levels: u32,
    pub jersey_number: Option<String>,
    pub joined_on: Date,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub guardians: Vec<Guardian>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StaffMember {
    pub role: StaffRole,
    pub given_name: String,
    pub family_name: String,
    pub since: Date,
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
        let mut checks = Checks::default();
        checks.rows("players", self.players.len(), MAX_PLAYERS);
        checks.rows("staff", self.staff.len(), MAX_STAFF);
        for (i, player) in self.players.iter().enumerate() {
            checks.rows(format!("players[{i}].guardians"), player.guardians.len(), MAX_GUARDIANS);
        }
        self.academy.check(&mut checks);
        checks.add(text::required("team.name", &self.team.name, MAX_TEAM_TEXT));
        checks.add(text::optional("team.season", self.team.season.as_deref(), MAX_TEAM_TEXT));
        checks.add(text::optional("team.category", self.team.category.as_deref(), MAX_TEAM_TEXT));
        for (i, player) in self.players.iter().enumerate() {
            check_player(&mut checks, &format!("players[{i}]"), player);
        }
        for (i, member) in self.staff.iter().enumerate() {
            let at = format!("staff[{i}]");
            check_person(&mut checks, &at, &member.given_name, &member.family_name);
            check_contact(&mut checks, &at, member.email.as_deref(), member.phone.as_deref());
        }
        checks.finish()
    }

    /// The sheet as printed on `printed_at` (the footer's date, in the academy's zone).
    pub fn document(&self, printed_at: Timestamp) -> PrintDocument {
        let t = |label| self.locale.text(label);
        let mut team = vec![Fact::new(t(Label::Team), self.team.name.clone())];
        team.extend(self.team.season.iter().map(|season| Fact::new(t(Label::Season), season.clone())));
        team.extend(self.team.category.iter().map(|category| Fact::new(t(Label::Category), category.clone())));
        PrintDocument {
            locale: self.locale,
            orientation: Orientation::Landscape,
            academy: self.academy.name.clone(),
            title: t(Label::TeamRosterTitle).to_owned(),
            blocks: vec![Block::Facts(team), Block::Table(self.players_table()), Block::Table(self.staff_table())],
            footer: crate::match_sheet::footer(self.locale, &self.academy, printed_at),
            page_word: t(Label::Page).to_owned(),
            of_word: t(Label::PageOf).to_owned(),
        }
    }

    /// `hoops-<academy>-roster-<team>-<yyyyMMdd>.pdf`, today in the academy's zone (as core's CSV, with `.pdf`).
    pub fn file_name(&self, printed_at: Timestamp) -> String {
        file_name::pdf(&self.academy.name, self.academy.day(printed_at), &["roster", &self.team.name])
    }

    fn players_table(&self) -> Table {
        let t = |label| self.locale.text(label);
        let columns = vec![
            Column::right(t(Label::Number), 3),
            Column::left(t(Label::Name), 12),
            Column::left(t(Label::BirthDate), 5),
            Column::left(t(Label::Gender), 5),
            Column::left(t(Label::AgeCategory), 5),
            Column::left(t(Label::Eligibility), 8),
            Column::left(t(Label::JoinedOn), 5),
            Column::left(t(Label::Email), 10),
            Column::left(t(Label::Phone), 6),
        ];
        let mut rows = Vec::new();
        for player in &self.players {
            rows.push(self.player_row(player));
            rows.extend(player.guardians.iter().map(|guardian| {
                Row::new(
                    RowStyle::Detail,
                    vec![
                        String::new(),
                        format!("{}: {}", t(Label::Guardian), full_name(&guardian.given_name, &guardian.family_name)),
                        String::new(),
                        String::new(),
                        String::new(),
                        String::new(),
                        String::new(),
                        guardian.email.clone().unwrap_or_default(),
                        guardian.phone.clone().unwrap_or_default(),
                    ],
                )
            }));
        }
        Table { heading: t(Label::Players).to_owned(), columns, rows, empty: t(Label::NoPlayers).to_owned() }
    }

    fn player_row(&self, player: &RosterPlayer) -> Row {
        let t = |label| self.locale.text(label);
        let gender = player.gender.map(|gender| {
            t(match gender {
                Gender::Male => Label::Male,
                Gender::Female => Label::Female,
            })
        });
        let eligibility = match player.eligibility {
            Eligibility::Eligible => t(Label::Eligible).to_owned(),
            Eligibility::PlayUp => format!("{} (+{})", t(Label::PlaysUp), player.play_up_levels),
            Eligibility::Ineligible => t(Label::NotEligible).to_owned(),
        };
        Row::new(
            RowStyle::Normal,
            vec![
                player.jersey_number.clone().unwrap_or_default(),
                full_name(&player.given_name, &player.family_name),
                player.birth_date.map(iso).unwrap_or_default(),
                gender.unwrap_or_default().to_owned(),
                player.age_category.clone().unwrap_or_default(),
                eligibility,
                iso(player.joined_on),
                player.email.clone().unwrap_or_default(),
                player.phone.clone().unwrap_or_default(),
            ],
        )
    }

    fn staff_table(&self) -> Table {
        let t = |label| self.locale.text(label);
        let columns = vec![
            Column::left(t(Label::Role), 8),
            Column::left(t(Label::Name), 12),
            Column::left(t(Label::Since), 5),
            Column::left(t(Label::Email), 10),
            Column::left(t(Label::Phone), 6),
        ];
        let rows = self
            .staff
            .iter()
            .map(|member| {
                let role = t(match member.role {
                    StaffRole::Coach => Label::Coach,
                    StaffRole::AssistantCoach => Label::AssistantCoach,
                });
                Row::new(
                    RowStyle::Normal,
                    vec![
                        role.to_owned(),
                        full_name(&member.given_name, &member.family_name),
                        iso(member.since),
                        member.email.clone().unwrap_or_default(),
                        member.phone.clone().unwrap_or_default(),
                    ],
                )
            })
            .collect();
        Table { heading: t(Label::Staff).to_owned(), columns, rows, empty: "—".to_owned() }
    }
}

fn check_player(checks: &mut Checks, at: &str, player: &RosterPlayer) {
    check_person(checks, at, &player.given_name, &player.family_name);
    checks.add(text::optional(&format!("{at}.ageCategory"), player.age_category.as_deref(), MAX_TEAM_TEXT));
    checks.add(text::jersey(&format!("{at}.jerseyNumber"), player.jersey_number.as_deref()));
    check_contact(checks, at, player.email.as_deref(), player.phone.as_deref());
    checks.add(text::within(&format!("{at}.playUpLevels"), player.play_up_levels, 0, 20));
    for (j, guardian) in player.guardians.iter().enumerate() {
        let at = format!("{at}.guardians[{j}]");
        check_person(checks, &at, &guardian.given_name, &guardian.family_name);
        check_contact(checks, &at, guardian.email.as_deref(), guardian.phone.as_deref());
    }
}

fn check_person(checks: &mut Checks, at: &str, given: &str, family: &str) {
    checks.add(text::required(&format!("{at}.givenName"), given, MAX_PERSON_NAME));
    checks.add(text::required(&format!("{at}.familyName"), family, MAX_PERSON_NAME));
}

fn check_contact(checks: &mut Checks, at: &str, email: Option<&str>, phone: Option<&str>) {
    checks.add(text::optional(&format!("{at}.email"), email, MAX_EMAIL));
    checks.add(text::optional(&format!("{at}.phone"), phone, MAX_PHONE));
}

/// "Family, Given": the roster is read by family name.
fn full_name(given: &str, family: &str) -> String {
    format!("{family}, {given}")
}

fn iso(day: Date) -> String {
    day.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use jiff::civil::date;
    use jiff::tz::TimeZone;

    fn day(m: i8, d: i8) -> Date {
        date(2026, m, d)
    }

    fn guardian(name: &str) -> Guardian {
        Guardian {
            given_name: name.into(),
            family_name: "Santoso".into(),
            email: Some("wali@example.test".into()),
            phone: Some("+62 811 000".into()),
        }
    }

    fn player() -> RosterPlayer {
        RosterPlayer {
            given_name: "Budi".into(),
            family_name: "Santoso".into(),
            birth_date: Some(date(2014, 3, 9)),
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
            academy: Academy { name: "Garuda Hoops".into(), time_zone: TimeZone::get("Asia/Jakarta").unwrap() },
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

    fn printed() -> Timestamp {
        "2026-11-15T18:00:00Z".parse::<Timestamp>().unwrap()
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
            Block::Facts(vec![
                Fact::new("Tim", "U12 Elang"),
                Fact::new("Musim", "2026/27"),
                Fact::new("Kategori", "U12")
            ])
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
            [
                "Nomor",
                "Nama",
                "Tanggal lahir",
                "Jenis kelamin",
                "Kategori usia",
                "Kelayakan",
                "Bergabung",
                "Email",
                "Telepon"
            ]
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
        assert_eq!(
            staff.rows[0].cells,
            ["Entrenador asistente", "Lestari, Dewi", "2026-08-15", "dewi@example.test", ""]
        );
        assert_eq!(staff.rows[1].cells[0], "Entrenador");
        assert_eq!(staff.empty, "—");
    }

    #[test]
    fn the_file_name_names_the_team_and_the_academys_day() {
        assert_eq!(roster().file_name(printed()), "hoops-garuda-hoops-roster-u12-elang-20261116.pdf");
    }
}
