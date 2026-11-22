//! The domain of pdf-service (ADR-0051 §3, ADR-0052): the two printable sheets, their limits, the labels of the
//! three languages, the file names, and the print document a renderer draws. No framework crates: only the
//! standard library, `jiff` (dates in the academy's time zone) and `unicode-normalization` (file names).

pub mod academy;
pub mod document;
pub mod error;
pub mod file_name;
pub mod labels;
pub mod match_sheet;
pub mod team_roster;
mod text;

pub use academy::Academy;
pub use document::{Align, Block, Column, Fact, Orientation, PrintDocument, Row, RowStyle, Table};
pub use error::{SheetError, Violation};
pub use labels::{Label, Locale};
pub use match_sheet::{HomeAway, MatchSheet, MatchStatus, PeriodScore, PlayerLine, Score, StatLine};
pub use team_roster::{Eligibility, Gender, Guardian, RosterPlayer, StaffMember, StaffRole, TeamInfo, TeamRoster};
