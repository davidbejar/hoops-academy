//! The printed labels in the three languages of the app (es / en / id, ADR-0048). Values are printed as sent;
//! only labels and enum values (status, home / away, gender, eligibility, staff role) are translated. The terms
//! follow core's export labels (`export_<lang>.properties`) and the web's ARB files.

/// A language of the app.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Locale {
    Es,
    En,
    Id,
}

impl Locale {
    pub const ALL: [Self; 3] = [Self::Es, Self::En, Self::Id];

    /// The contract's code (`es`, `en`, `id`), also the PDF's document language.
    pub fn code(self) -> &'static str {
        match self {
            Self::Es => "es",
            Self::En => "en",
            Self::Id => "id",
        }
    }

    pub fn text(self, label: Label) -> &'static str {
        let [es, en, id] = label.texts();
        match self {
            Self::Es => es,
            Self::En => en,
            Self::Id => id,
        }
    }
}

/// Everything a sheet prints besides the caller's values.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Label {
    MatchSheetTitle,
    TeamRosterTitle,
    Team,
    Opponent,
    Home,
    Away,
    Date,
    Time,
    TimeZone,
    Venue,
    Status,
    Scheduled,
    Live,
    Finished,
    Cancelled,
    Periods,
    PeriodsHeading,
    OvertimeShort,
    Total,
    BoxScoreHeading,
    Number,
    Player,
    StarterNote,
    Minutes,
    Points,
    FreeThrows,
    TwoPointers,
    ThreePointers,
    OffensiveRebounds,
    DefensiveRebounds,
    Rebounds,
    Assists,
    Steals,
    Blocks,
    Turnovers,
    Fouls,
    TeamTotals,
    NoPlayers,
    Season,
    Category,
    Players,
    Staff,
    Name,
    BirthDate,
    Gender,
    Male,
    Female,
    AgeCategory,
    Eligibility,
    Eligible,
    PlaysUp,
    NotEligible,
    JoinedOn,
    Email,
    Phone,
    Guardian,
    Role,
    Coach,
    AssistantCoach,
    Since,
    PrintedOn,
    Page,
    PageOf,
}

impl Label {
    pub const ALL: [Self; 63] = [
        Self::MatchSheetTitle,
        Self::TeamRosterTitle,
        Self::Team,
        Self::Opponent,
        Self::Home,
        Self::Away,
        Self::Date,
        Self::Time,
        Self::TimeZone,
        Self::Venue,
        Self::Status,
        Self::Scheduled,
        Self::Live,
        Self::Finished,
        Self::Cancelled,
        Self::Periods,
        Self::PeriodsHeading,
        Self::OvertimeShort,
        Self::Total,
        Self::BoxScoreHeading,
        Self::Number,
        Self::Player,
        Self::StarterNote,
        Self::Minutes,
        Self::Points,
        Self::FreeThrows,
        Self::TwoPointers,
        Self::ThreePointers,
        Self::OffensiveRebounds,
        Self::DefensiveRebounds,
        Self::Rebounds,
        Self::Assists,
        Self::Steals,
        Self::Blocks,
        Self::Turnovers,
        Self::Fouls,
        Self::TeamTotals,
        Self::NoPlayers,
        Self::Season,
        Self::Category,
        Self::Players,
        Self::Staff,
        Self::Name,
        Self::BirthDate,
        Self::Gender,
        Self::Male,
        Self::Female,
        Self::AgeCategory,
        Self::Eligibility,
        Self::Eligible,
        Self::PlaysUp,
        Self::NotEligible,
        Self::JoinedOn,
        Self::Email,
        Self::Phone,
        Self::Guardian,
        Self::Role,
        Self::Coach,
        Self::AssistantCoach,
        Self::Since,
        Self::PrintedOn,
        Self::Page,
        Self::PageOf,
    ];

    /// `[es, en, id]`.
    #[allow(clippy::too_many_lines)] // one table, one line per label
    fn texts(self) -> [&'static str; 3] {
        match self {
            Self::MatchSheetTitle => ["Acta del partido", "Match sheet", "Lembar pertandingan"],
            Self::TeamRosterTitle => ["Plantilla del equipo", "Team roster", "Daftar tim"],
            Self::Team => ["Equipo", "Team", "Tim"],
            Self::Opponent => ["Rival", "Opponent", "Lawan"],
            Self::Home => ["Local", "Home", "Kandang"],
            Self::Away => ["Visitante", "Away", "Tandang"],
            Self::Date => ["Fecha", "Date", "Tanggal"],
            Self::Time => ["Hora", "Time", "Jam"],
            Self::TimeZone => ["Zona horaria", "Time zone", "Zona waktu"],
            Self::Venue => ["Lugar", "Venue", "Tempat"],
            Self::Status => ["Estado", "Status", "Status"],
            Self::Scheduled => ["Programado", "Scheduled", "Terjadwal"],
            Self::Live => ["En juego", "Live", "Berlangsung"],
            Self::Finished => ["Finalizado", "Finished", "Selesai"],
            Self::Cancelled => ["Cancelado", "Cancelled", "Dibatalkan"],
            Self::Periods => ["Periodos", "Periods", "Periode"],
            Self::PeriodsHeading => ["Marcador por periodo", "Score by period", "Skor per periode"],
            Self::OvertimeShort => ["PR", "OT", "OT"],
            Self::Total => ["Total", "Total", "Total"],
            Self::BoxScoreHeading => ["Estadísticas", "Box score", "Statistik"],
            Self::Number => ["Dorsal", "No.", "Nomor"],
            Self::Player => ["Jugador", "Player", "Pemain"],
            Self::StarterNote => ["* titular", "* starter", "* starter"],
            Self::Minutes => ["MIN", "MIN", "MNT"],
            Self::Points => ["PTS", "PTS", "POIN"],
            Self::FreeThrows => ["TL", "FT", "FT"],
            Self::TwoPointers => ["T2", "2P", "2P"],
            Self::ThreePointers => ["T3", "3P", "3P"],
            Self::OffensiveRebounds => ["RO", "OREB", "ORB"],
            Self::DefensiveRebounds => ["RD", "DREB", "DRB"],
            Self::Rebounds => ["REB", "REB", "REB"],
            Self::Assists => ["AS", "AST", "AST"],
            Self::Steals => ["BR", "STL", "STL"],
            Self::Blocks => ["TAP", "BLK", "BLK"],
            Self::Turnovers => ["PÉR", "TO", "TO"],
            Self::Fouls => ["FP", "PF", "PF"],
            Self::TeamTotals => ["Totales del equipo", "Team totals", "Total tim"],
            Self::NoPlayers => ["Sin jugadores", "No players", "Tidak ada pemain"],
            Self::Season => ["Temporada", "Season", "Musim"],
            Self::Category => ["Categoría", "Category", "Kategori"],
            Self::Players => ["Jugadores", "Players", "Pemain"],
            Self::Staff => ["Cuerpo técnico", "Staff", "Staf pelatih"],
            Self::Name => ["Nombre", "Name", "Nama"],
            Self::BirthDate => ["Fecha de nacimiento", "Birth date", "Tanggal lahir"],
            Self::Gender => ["Género", "Gender", "Jenis kelamin"],
            Self::Male => ["Masculino", "Male", "Laki-laki"],
            Self::Female => ["Femenino", "Female", "Perempuan"],
            Self::AgeCategory => ["Categoría de edad", "Age category", "Kategori usia"],
            Self::Eligibility => ["Elegibilidad", "Eligibility", "Kelayakan"],
            Self::Eligible => ["Elegible", "Eligible", "Memenuhi syarat"],
            Self::PlaysUp => ["Juega en categoría superior", "Plays up", "Naik kategori"],
            Self::NotEligible => ["No elegible", "Not eligible", "Tidak memenuhi syarat"],
            Self::JoinedOn => ["Alta en el equipo", "Joined on", "Bergabung"],
            Self::Email => ["Correo electrónico", "E-mail", "Email"],
            Self::Phone => ["Teléfono", "Phone", "Telepon"],
            Self::Guardian => ["Tutor", "Guardian", "Wali"],
            Self::Role => ["Rol", "Role", "Peran"],
            Self::Coach => ["Entrenador", "Coach", "Pelatih"],
            Self::AssistantCoach => ["Entrenador asistente", "Assistant coach", "Asisten pelatih"],
            Self::Since => ["Desde", "Since", "Sejak"],
            Self::PrintedOn => ["Impreso el", "Printed on", "Dicetak pada"],
            Self::Page => ["Página", "Page", "Halaman"],
            Self::PageOf => ["de", "of", "dari"],
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    #[test]
    fn every_label_has_a_text_in_every_language() {
        for label in Label::ALL {
            for locale in Locale::ALL {
                assert!(!locale.text(label).trim().is_empty(), "{label:?} in {locale:?}");
            }
        }
    }

    #[test]
    fn the_list_of_labels_has_no_duplicates() {
        assert_eq!(Label::ALL.iter().collect::<HashSet<_>>().len(), Label::ALL.len());
    }

    #[test]
    fn titles_differ_per_language() {
        let titles: HashSet<_> = Locale::ALL.iter().map(|l| l.text(Label::MatchSheetTitle)).collect();
        assert_eq!(titles.len(), 3);
        assert_eq!(Locale::Es.text(Label::TeamRosterTitle), "Plantilla del equipo");
        assert_eq!(Locale::Id.text(Label::TeamRosterTitle), "Daftar tim");
    }

    #[test]
    fn codes_are_the_contracts() {
        assert_eq!(Locale::ALL.map(Locale::code), ["es", "en", "id"]);
    }
}
