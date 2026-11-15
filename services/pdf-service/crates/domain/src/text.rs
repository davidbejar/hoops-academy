//! Field checks shared by the sheets: texts are printed as given, so they must be non-blank, short enough for a
//! table cell and free of control characters (a line break would leave its cell).

use crate::error::Violation;

/// A required text of at most `max` characters.
pub(crate) fn required(field: &str, value: &str, max: usize) -> Option<Violation> {
    if value.trim().is_empty() {
        return Some(Violation::new(field, "BLANK", "must not be blank"));
    }
    optional(field, Some(value), max)
}

/// An optional text: absent is fine, present follows [`required`]'s length and character rules (blank allowed).
pub(crate) fn optional(field: &str, value: Option<&str>, max: usize) -> Option<Violation> {
    let value = value?;
    if value.chars().count() > max {
        return Some(Violation::new(field, "TOO_LONG", "is longer than the contract allows"));
    }
    if value.chars().any(char::is_control) {
        return Some(Violation::new(field, "CONTROL_CHARACTER", "must not contain control characters"));
    }
    None
}

/// A jersey number: one or two digits ("0" and "00" differ), as in core and game.
pub(crate) fn jersey(field: &str, value: Option<&str>) -> Option<Violation> {
    let value = value?;
    let valid = (1..=2).contains(&value.len()) && value.bytes().all(|b| b.is_ascii_digit());
    (!valid).then(|| Violation::new(field, "INVALID_JERSEY_NUMBER", "must be one or two digits"))
}

/// A whole number within `min..=max`.
pub(crate) fn within(field: &str, value: u32, min: u32, max: u32) -> Option<Violation> {
    (!(min..=max).contains(&value)).then(|| Violation::new(field, "OUT_OF_RANGE", "is outside the allowed range"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_required_text_is_not_blank() {
        assert_eq!(required("name", "  ", 10).map(|v| v.code), Some("BLANK"));
        assert_eq!(required("name", "Lions", 10), None);
    }

    #[test]
    fn a_text_counts_characters_not_bytes() {
        assert_eq!(required("name", "ñañañ", 5), None);
        assert_eq!(required("name", "ñañaña", 5).map(|v| v.code), Some("TOO_LONG"));
    }

    #[test]
    fn control_characters_are_refused() {
        assert_eq!(optional("venue", Some("a\nb"), 10).map(|v| v.code), Some("CONTROL_CHARACTER"));
        assert_eq!(optional("venue", Some("a\u{7}b"), 10).map(|v| v.field), Some("venue".to_owned()));
    }

    #[test]
    fn an_absent_optional_text_is_fine() {
        assert_eq!(optional("venue", None, 10), None);
        assert_eq!(optional("venue", Some(""), 10), None);
    }

    #[test]
    fn jersey_numbers_are_one_or_two_digits() {
        for ok in ["0", "00", "7", "23"] {
            assert_eq!(jersey("n", Some(ok)), None, "{ok}");
        }
        for bad in ["", "123", "7a", "-1", "٣"] {
            assert_eq!(jersey("n", Some(bad)).map(|v| v.code), Some("INVALID_JERSEY_NUMBER"), "{bad}");
        }
        assert_eq!(jersey("n", None), None);
    }

    #[test]
    fn numbers_stay_within_their_range() {
        assert_eq!(within("p", 1, 1, 8), None);
        assert_eq!(within("p", 8, 1, 8), None);
        assert_eq!(within("p", 0, 1, 8).map(|v| v.code), Some("OUT_OF_RANGE"));
        assert_eq!(within("p", 9, 1, 8).map(|v| v.code), Some("OUT_OF_RANGE"));
    }
}
