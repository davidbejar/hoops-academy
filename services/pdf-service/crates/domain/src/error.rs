//! Why a sheet is refused: field violations (the caller sent something the contract forbids) or more rows than a
//! sheet prints (the limits of [`crate::match_sheet`] and [`crate::team_roster`]).

use std::fmt;

/// One offending field: its dotted path in the request body and a stable code. Never the value itself.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Violation {
    pub field: String,
    pub code: &'static str,
    pub message: &'static str,
}

impl Violation {
    pub fn new(field: impl Into<String>, code: &'static str, message: &'static str) -> Self {
        Self { field: field.into(), code, message }
    }
}

/// A sheet that cannot be printed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SheetError {
    /// One or more fields break the contract (HTTP 400).
    Invalid(Vec<Violation>),
    /// A list holds more rows than the sheet prints (HTTP 422 `TOO_MANY_ROWS`).
    TooManyRows { field: String, max: usize },
}

impl fmt::Display for SheetError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Invalid(violations) => write!(f, "{} invalid field(s)", violations.len()),
            Self::TooManyRows { field, max } => write!(f, "{field} holds more than {max} rows"),
        }
    }
}

impl std::error::Error for SheetError {}

/// Collects violations while a sheet is checked; rows over a limit win over field violations.
#[derive(Debug, Default)]
pub(crate) struct Checks {
    violations: Vec<Violation>,
    too_many: Option<(String, usize)>,
}

impl Checks {
    pub(crate) fn add(&mut self, violation: Option<Violation>) {
        self.violations.extend(violation);
    }

    pub(crate) fn rows(&mut self, field: impl Into<String>, count: usize, max: usize) {
        if count > max && self.too_many.is_none() {
            self.too_many = Some((field.into(), max));
        }
    }

    pub(crate) fn finish(self) -> Result<(), SheetError> {
        if let Some((field, max)) = self.too_many {
            return Err(SheetError::TooManyRows { field, max });
        }
        if self.violations.is_empty() { Ok(()) } else { Err(SheetError::Invalid(self.violations)) }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn no_violation_is_ok() {
        assert_eq!(Checks::default().finish(), Ok(()));
    }

    #[test]
    fn violations_are_reported_together() {
        let mut checks = Checks::default();
        checks.add(Some(Violation::new("a", "TOO_LONG", "too long")));
        checks.add(None);
        checks.add(Some(Violation::new("b", "BLANK", "blank")));
        let Err(SheetError::Invalid(violations)) = checks.finish() else { panic!("expected violations") };
        assert_eq!(violations.iter().map(|v| v.field.as_str()).collect::<Vec<_>>(), ["a", "b"]);
    }

    #[test]
    fn too_many_rows_wins_and_keeps_the_first_list() {
        let mut checks = Checks::default();
        checks.add(Some(Violation::new("a", "TOO_LONG", "too long")));
        checks.rows("players", 31, 30);
        checks.rows("staff", 21, 20);
        checks.rows("periodScores", 3, 12);
        assert_eq!(checks.finish(), Err(SheetError::TooManyRows { field: "players".into(), max: 30 }));
    }

    #[test]
    fn errors_describe_themselves_without_values() {
        let invalid = SheetError::Invalid(vec![Violation::new("a", "BLANK", "blank")]);
        assert_eq!(invalid.to_string(), "1 invalid field(s)");
        let rows = SheetError::TooManyRows { field: "players".into(), max: 60 };
        assert_eq!(rows.to_string(), "players holds more than 60 rows");
    }
}
