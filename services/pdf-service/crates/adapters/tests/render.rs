//! The krilla renderer draws both sheets in es / en / id, readable back as text, deterministic, paginated.

mod common;

use common::{match_sheet, page_count, pdf_text, player, printed_at, team_roster};
use pdf_adapters::render::KrillaRenderer;
use pdf_application::PdfRenderer;
use pdf_domain::Locale;

fn render(document: &pdf_domain::PrintDocument) -> Vec<u8> {
    KrillaRenderer::new().expect("bundled fonts").render(document).expect("a PDF")
}

#[test]
fn the_match_sheet_reads_back_in_every_language() {
    for (locale, expected) in [
        (
            Locale::Es,
            ["Acta del partido", "Estadísticas", "Marcador por periodo", "Totales del equipo", "Página 1 de 1"],
        ),
        (Locale::En, ["Match sheet", "Box score", "Score by period", "Team totals", "Page 1 of 1"]),
        (Locale::Id, ["Lembar pertandingan", "Statistik", "Skor per periode", "Total tim", "Halaman 1 dari 1"]),
    ] {
        let pdf = render(&match_sheet(locale).document(printed_at()));
        let text = pdf_text(&pdf);
        for label in expected {
            assert!(text.contains(label), "{locale:?} lacks {label:?} in {text}");
        }
        for value in ["Academia Ñandú", "U12 Leones 52 – 48 CB Halcones", "Lucía Martínez *", "Pabellón Norte"] {
            assert!(text.contains(value), "{locale:?} lacks {value:?}");
        }
        assert!(text.contains("2026-11-15 10:41 (Europe/Madrid)"), "the footer in the academy's zone: {text}");
    }
}

#[test]
fn the_team_roster_reads_back_in_every_language() {
    for (locale, expected) in [
        (Locale::Es, ["Plantilla del equipo", "Jugadores", "Cuerpo técnico", "Tutor: Santoso, Wali0", "Entrenador"]),
        (Locale::En, ["Team roster", "Players", "Staff", "Guardian: Santoso, Wali0", "Coach"]),
        (Locale::Id, ["Daftar tim", "Pemain", "Staf pelatih", "Wali: Santoso, Wali0", "Pelatih"]),
    ] {
        let text = pdf_text(&render(&team_roster(locale).document(printed_at())));
        for label in expected {
            assert!(text.contains(label), "{locale:?} lacks {label:?} in {text}");
        }
        assert!(text.contains("Santoso, Sari") && text.contains("Lestari, Dewi"), "{text}");
    }
}

#[test]
fn the_same_sheet_at_the_same_minute_gives_the_same_bytes() {
    let document = match_sheet(Locale::Es).document(printed_at());
    assert_eq!(render(&document), render(&document));
    let later = match_sheet(Locale::Es).document(printed_at() + chrono::Duration::minutes(1));
    assert_ne!(render(&document), render(&later));
}

#[test]
fn a_long_roster_flows_over_pages_with_the_header_repeated() {
    let mut roster = team_roster(Locale::En);
    roster.players = (0..60).map(|i| player(&format!("Player{i:02}"), 4)).collect();
    let pdf = render(&roster.document(printed_at()));
    let pages = page_count(&pdf);
    assert!(pages >= 4, "60 players with 4 guardians each need several pages, got {pages}");
    let text = pdf_text(&pdf);
    for (index, page) in text.split('\u{c}').enumerate() {
        assert!(page.contains("Garuda Hoops") && page.contains("Team roster"), "page {index} has the heading");
        assert!(page.contains(&format!("Page {} of {pages}", index + 1)), "page {index}: {page}");
    }
    assert!(text.contains("Santoso, Player00") && text.contains("Santoso, Player59"));
    let header_rows = text.matches("Birth date").count();
    assert!(header_rows >= pages - 1, "the players' header repeats on each page they flow over: {header_rows}");
}

#[test]
fn a_cell_longer_than_its_column_is_cut() {
    let mut sheet = match_sheet(Locale::En);
    let long = "Maximiliana Alejandra de la Santísima Trinidad Fernández-Villaverde y Montenegro";
    sheet.players[0].display_name = long.into();
    let text = pdf_text(&render(&sheet.document(printed_at())));
    assert!(!text.contains(long), "the name does not run into the next column");
    assert!(text.contains("Maximiliana") && text.contains('…'), "{text}");
}

#[test]
fn an_empty_table_prints_its_empty_text() {
    let mut roster = team_roster(Locale::En);
    roster.players.clear();
    roster.staff.clear();
    let text = pdf_text(&render(&roster.document(printed_at())));
    assert!(text.contains("No players") && text.contains('—'), "{text}");
}

#[test]
fn the_pdf_carries_no_link_no_script_and_no_creation_date() {
    let pdf = render(&team_roster(Locale::Es).document(printed_at()));
    let raw = String::from_utf8_lossy(&pdf);
    for forbidden in ["/URI", "/JavaScript", "/JS", "/Launch", "/CreationDate", "/EmbeddedFile"] {
        assert!(!raw.contains(forbidden), "{forbidden}");
    }
    assert!(raw.starts_with("%PDF-"));
    let metadata = lopdf::Document::load_mem(&pdf).unwrap().trailer.get(b"Info").is_ok();
    assert!(metadata, "title and language are set");
}
