//! The academy a sheet is printed for: its name heads every page and its time zone dates every time on it.

use jiff::Timestamp;
use jiff::civil::Date;
use jiff::tz::TimeZone;

use crate::error::{Checks, Violation};
use crate::text;

/// Longest academy name core accepts (`core.yaml`, academy name).
pub const MAX_NAME: usize = 120;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Academy {
    pub name: String,
    pub time_zone: TimeZone,
}

impl Academy {
    /// An IANA zone id such as `Europe/Madrid` or `Asia/Jakarta`; anything else is a violation of `field`.
    /// The id is matched exactly: the database lookup alone would also take `europe/madrid`.
    pub fn time_zone(field: &str, id: &str) -> Result<TimeZone, Violation> {
        TimeZone::get(id)
            .ok()
            .filter(|zone| zone.iana_name() == Some(id))
            .ok_or_else(|| Violation::new(field, "INVALID_TIME_ZONE", "is not an IANA time zone id"))
    }

    /// The IANA id of the academy's zone, as printed on a sheet. `time_zone` only yields zones that have one.
    pub fn zone_id(&self) -> &str {
        self.time_zone.iana_name().unwrap_or_default()
    }

    /// The calendar day of `instant` in the academy's zone.
    pub fn day(&self, instant: Timestamp) -> Date {
        instant.to_zoned_datetime(self.time_zone.clone()).date()
    }

    /// `yyyy-MM-dd` and `HH:mm` of `instant` in the academy's zone (ADR-0048).
    pub fn date_and_time(&self, instant: Timestamp) -> (String, String) {
        let local = instant.to_zoned_datetime(self.time_zone.clone());
        (local.strftime("%Y-%m-%d").to_string(), local.strftime("%H:%M").to_string())
    }

    pub(crate) fn check(&self, checks: &mut Checks) {
        checks.add(text::required("academy.name", &self.name, MAX_NAME));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use jiff::civil::date;

    fn jakarta() -> Academy {
        Academy { name: "Garuda Hoops".into(), time_zone: TimeZone::get("Asia/Jakarta").unwrap() }
    }

    #[test]
    fn a_zone_id_is_parsed_or_refused() {
        assert_eq!(
            Academy::time_zone("academy.timeZone", "Europe/Madrid"),
            Ok(TimeZone::get("Europe/Madrid").unwrap())
        );
        let refused = Academy::time_zone("academy.timeZone", "Mars/Olympus").unwrap_err();
        assert_eq!((refused.field.as_str(), refused.code), ("academy.timeZone", "INVALID_TIME_ZONE"));
    }

    #[test]
    fn days_and_times_are_the_academys() {
        let late_utc = "2026-11-15T18:30:00Z".parse::<Timestamp>().unwrap();
        assert_eq!(jakarta().day(late_utc), date(2026, 11, 16));
        assert_eq!(jakarta().date_and_time(late_utc), ("2026-11-16".to_owned(), "01:30".to_owned()));
    }

    #[test]
    fn the_name_is_required() {
        let mut checks = Checks::default();
        Academy { name: " ".into(), ..jakarta() }.check(&mut checks);
        assert!(checks.finish().is_err());
    }
}
