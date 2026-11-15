//! The academy a sheet is printed for: its name heads every page and its time zone dates every time on it.

use chrono::{DateTime, NaiveDate, Utc};
use chrono_tz::Tz;

use crate::error::{Checks, Violation};
use crate::text;

/// Longest academy name core accepts (`core.yaml`, academy name).
pub const MAX_NAME: usize = 120;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Academy {
    pub name: String,
    pub time_zone: Tz,
}

impl Academy {
    /// An IANA zone id such as `Europe/Madrid` or `Asia/Jakarta`; anything else is a violation of `field`.
    pub fn time_zone(field: &str, id: &str) -> Result<Tz, Violation> {
        id.parse::<Tz>().map_err(|_| Violation::new(field, "INVALID_TIME_ZONE", "is not an IANA time zone id"))
    }

    /// The calendar day of `instant` in the academy's zone.
    pub fn day(&self, instant: DateTime<Utc>) -> NaiveDate {
        instant.with_timezone(&self.time_zone).date_naive()
    }

    /// `yyyy-MM-dd` and `HH:mm` of `instant` in the academy's zone (ADR-0048).
    pub fn date_and_time(&self, instant: DateTime<Utc>) -> (String, String) {
        let local = instant.with_timezone(&self.time_zone);
        (local.format("%Y-%m-%d").to_string(), local.format("%H:%M").to_string())
    }

    pub(crate) fn check(&self, checks: &mut Checks) {
        checks.add(text::required("academy.name", &self.name, MAX_NAME));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn jakarta() -> Academy {
        Academy { name: "Garuda Hoops".into(), time_zone: chrono_tz::Asia::Jakarta }
    }

    #[test]
    fn a_zone_id_is_parsed_or_refused() {
        assert_eq!(Academy::time_zone("academy.timeZone", "Europe/Madrid"), Ok(chrono_tz::Europe::Madrid));
        let refused = Academy::time_zone("academy.timeZone", "Mars/Olympus").unwrap_err();
        assert_eq!((refused.field.as_str(), refused.code), ("academy.timeZone", "INVALID_TIME_ZONE"));
    }

    #[test]
    fn days_and_times_are_the_academys() {
        let late_utc = Utc.with_ymd_and_hms(2026, 11, 15, 18, 30, 0).unwrap();
        assert_eq!(jakarta().day(late_utc), NaiveDate::from_ymd_opt(2026, 11, 16).unwrap());
        assert_eq!(jakarta().date_and_time(late_utc), ("2026-11-16".to_owned(), "01:30".to_owned()));
    }

    #[test]
    fn the_name_is_required() {
        let mut checks = Checks::default();
        Academy { name: " ".into(), ..jakarta() }.check(&mut checks);
        assert!(checks.finish().is_err());
    }
}
