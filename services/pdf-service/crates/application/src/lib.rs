//! Use cases of pdf-service and their ports (ADR-0052). Depends on `pdf-domain` only (and `jiff` for the clock).
//!
//! A use case checks the sheet (limits, then field rules), builds its print document for "now" in the academy's
//! zone, has the renderer draw it and names the file. Nothing is stored and nothing is logged here.

use std::fmt;
use std::sync::Arc;

use jiff::Timestamp;
use pdf_domain::{MatchSheet, PrintDocument, SheetError, TeamRoster};

/// Draws a print document as PDF bytes (driven adapter: the krilla renderer).
pub trait PdfRenderer: Send + Sync {
    fn render(&self, document: &PrintDocument) -> Result<Vec<u8>, RenderError>;
}

/// Now (driven adapter: the system clock; tests fix it, which makes the output deterministic).
pub trait Clock: Send + Sync {
    fn now(&self) -> Timestamp;
}

/// The renderer failed; the reason is for the service log, never for the caller.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RenderError(pub String);

impl fmt::Display for RenderError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "rendering failed: {}", self.0)
    }
}

impl std::error::Error for RenderError {}

/// A rendered sheet.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RenderedPdf {
    pub file_name: String,
    pub bytes: Vec<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PrintError {
    /// The sheet breaks a rule (400 / 422).
    Rejected(SheetError),
    /// The renderer failed (500).
    Failed(RenderError),
}

impl From<SheetError> for PrintError {
    fn from(error: SheetError) -> Self {
        Self::Rejected(error)
    }
}

impl From<RenderError> for PrintError {
    fn from(error: RenderError) -> Self {
        Self::Failed(error)
    }
}

/// The two use cases: print a match sheet, print a team roster.
#[derive(Clone)]
pub struct PrintSheets {
    renderer: Arc<dyn PdfRenderer>,
    clock: Arc<dyn Clock>,
}

impl fmt::Debug for PrintSheets {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("PrintSheets")
    }
}

impl PrintSheets {
    pub fn new(renderer: Arc<dyn PdfRenderer>, clock: Arc<dyn Clock>) -> Self {
        Self { renderer, clock }
    }

    pub fn match_sheet(&self, sheet: &MatchSheet) -> Result<RenderedPdf, PrintError> {
        sheet.check()?;
        let now = self.clock.now();
        self.print(&sheet.document(now), sheet.file_name(now))
    }

    pub fn team_roster(&self, roster: &TeamRoster) -> Result<RenderedPdf, PrintError> {
        roster.check()?;
        let now = self.clock.now();
        self.print(&roster.document(now), roster.file_name(now))
    }

    fn print(&self, document: &PrintDocument, file_name: String) -> Result<RenderedPdf, PrintError> {
        Ok(RenderedPdf { file_name, bytes: self.renderer.render(document)? })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use jiff::civil::date;
    use jiff::tz::TimeZone;
    use pdf_domain::{Academy, Eligibility, HomeAway, Locale, MatchStatus, RosterPlayer, Score, StatLine, TeamInfo};
    use std::sync::Mutex;

    /// Remembers the documents it was given and answers their title as "PDF".
    #[derive(Default)]
    struct FakeRenderer {
        seen: Mutex<Vec<PrintDocument>>,
        fail: bool,
    }

    impl PdfRenderer for FakeRenderer {
        fn render(&self, document: &PrintDocument) -> Result<Vec<u8>, RenderError> {
            self.seen.lock().unwrap().push(document.clone());
            if self.fail { Err(RenderError("font".into())) } else { Ok(document.title.clone().into_bytes()) }
        }
    }

    struct FixedClock;

    impl Clock for FixedClock {
        fn now(&self) -> Timestamp {
            "2026-11-15T12:00:00Z".parse::<Timestamp>().unwrap()
        }
    }

    fn academy() -> Academy {
        Academy { name: "Hoops Sur".into(), time_zone: TimeZone::get("Europe/Madrid").unwrap() }
    }

    fn sheet() -> MatchSheet {
        MatchSheet {
            locale: Locale::Es,
            academy: academy(),
            team_name: "Leones".into(),
            opponent_name: "Halcones".into(),
            home_away: HomeAway::Away,
            scheduled_at: "2026-11-14T09:00:00Z".parse::<Timestamp>().unwrap(),
            venue: None,
            status: MatchStatus::Finished,
            period_count: 4,
            period_minutes: 10,
            score: Score { team: 40, opponent: 38 },
            period_scores: vec![],
            team_totals: StatLine::default(),
            players: vec![],
        }
    }

    fn roster() -> TeamRoster {
        TeamRoster {
            locale: Locale::En,
            academy: academy(),
            team: TeamInfo { name: "U12 Lions".into(), season: None, category: None },
            players: vec![RosterPlayer {
                given_name: "Ana".into(),
                family_name: "García".into(),
                birth_date: None,
                gender: None,
                age_category: None,
                eligibility: Eligibility::Eligible,
                play_up_levels: 0,
                jersey_number: None,
                joined_on: date(2026, 9, 1),
                email: None,
                phone: None,
                guardians: vec![],
            }],
            staff: vec![],
        }
    }

    fn sheets(renderer: Arc<FakeRenderer>) -> PrintSheets {
        PrintSheets::new(renderer, Arc::new(FixedClock))
    }

    #[test]
    fn a_match_sheet_is_rendered_and_named_for_today() {
        let renderer = Arc::new(FakeRenderer::default());
        let pdf = sheets(renderer.clone()).match_sheet(&sheet()).unwrap();
        assert_eq!(pdf.bytes, b"Acta del partido");
        assert_eq!(pdf.file_name, "hoops-hoops-sur-match-sheet-leones-halcones-20261115.pdf");
        let seen = renderer.seen.lock().unwrap();
        assert_eq!(seen[0].footer, "Impreso el 2026-11-15 13:00 (Europe/Madrid)");
    }

    #[test]
    fn a_team_roster_is_rendered_and_named_for_today() {
        let pdf = sheets(Arc::new(FakeRenderer::default())).team_roster(&roster()).unwrap();
        assert_eq!(pdf.bytes, b"Team roster");
        assert_eq!(pdf.file_name, "hoops-hoops-sur-roster-u12-lions-20261115.pdf");
    }

    #[test]
    fn a_rejected_sheet_never_reaches_the_renderer() {
        let renderer = Arc::new(FakeRenderer::default());
        let mut too_long = roster();
        too_long.players = vec![too_long.players[0].clone(); 61];
        let error = sheets(renderer.clone()).team_roster(&too_long).unwrap_err();
        assert_eq!(error, PrintError::Rejected(SheetError::TooManyRows { field: "players".into(), max: 60 }));
        let mut blank = sheet();
        blank.team_name = String::new();
        assert!(matches!(sheets(renderer.clone()).match_sheet(&blank), Err(PrintError::Rejected(_))));
        assert!(renderer.seen.lock().unwrap().is_empty());
    }

    #[test]
    fn a_renderer_failure_is_reported_as_such() {
        let renderer = Arc::new(FakeRenderer { fail: true, ..FakeRenderer::default() });
        let error = sheets(renderer).match_sheet(&sheet()).unwrap_err();
        assert_eq!(error, PrintError::Failed(RenderError("font".into())));
        assert_eq!(RenderError("font".into()).to_string(), "rendering failed: font");
        assert_eq!(format!("{:?}", sheets(Arc::new(FakeRenderer::default()))), "PrintSheets");
    }
}
