//! `hoops-<academy>-<what>-<yyyyMMdd>.pdf` (ADR-0048's pattern, as core's `ExportFileName`): each part reduced to
//! lower-case ASCII words joined by `-` (accents dropped, anything else a separator, at most 40 characters), a part
//! with nothing left is left out. The day is today in the academy's time zone.

use jiff::civil::Date;
use unicode_normalization::UnicodeNormalization;
use unicode_normalization::char::is_combining_mark;

const MAX_PART: usize = 40;

/// The file name of a PDF for `academy`, describing `what` (e.g. `["roster", "U12 Lions"]`), printed on `day`.
pub fn pdf(academy: &str, day: Date, what: &[&str]) -> String {
    let parts: Vec<String> =
        std::iter::once("hoops").chain(std::iter::once(academy)).chain(what.iter().copied()).map(ascii).collect();
    let words: Vec<&str> = parts.iter().map(String::as_str).filter(|part| !part.is_empty()).collect();
    format!("{}-{}.pdf", words.join("-"), day.strftime("%Y%m%d"))
}

/// Lower-case ASCII letters and digits, runs of anything else as one `-`, trimmed, at most 40 characters.
pub fn ascii(text: &str) -> String {
    let mut out = String::new();
    for ch in text.nfkd().filter(|ch| !is_combining_mark(*ch)) {
        let ch = ch.to_ascii_lowercase();
        if ch.is_ascii_lowercase() || ch.is_ascii_digit() {
            out.push(ch);
        } else if !out.ends_with('-') {
            out.push('-');
        }
    }
    let trimmed = out.trim_matches('-');
    trimmed[..trimmed.len().min(MAX_PART)].trim_matches('-').to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn day() -> Date {
        use jiff::civil::date;
        date(2026, 11, 5)
    }

    #[test]
    fn parts_are_ascii_words() {
        assert_eq!(ascii("Club Baloncesto Ñandú"), "club-baloncesto-nandu");
        assert_eq!(ascii("  U12 — Lions!! "), "u12-lions");
        assert_eq!(ascii("Ærø"), "r");
        assert_eq!(ascii("★★★"), "");
    }

    #[test]
    fn a_part_is_cut_at_forty_characters_without_a_trailing_dash() {
        let long = "abcdefghij abcdefghij abcdefghij abcdefgh ijk";
        let part = ascii(long);
        assert_eq!(part, "abcdefghij-abcdefghij-abcdefghij-abcdefg");
        assert_eq!(ascii("abcdefghij abcdefghij abcdefghij abcdefg- tail"), "abcdefghij-abcdefghij-abcdefghij-abcdefg");
    }

    #[test]
    fn the_file_name_follows_the_export_pattern() {
        assert_eq!(
            pdf("Academia Sur", day(), &["roster", "U12 Leones"]),
            "hoops-academia-sur-roster-u12-leones-20261105.pdf"
        );
        assert_eq!(pdf("★", day(), &["match-sheet", "", "Rivals"]), "hoops-match-sheet-rivals-20261105.pdf");
    }
}
