//! The print document: what a sheet looks like, independent of the PDF engine. The sheets build it (labels, values
//! formatted in the academy's zone); a renderer (port of the application layer) only draws it: page size, fonts,
//! pagination with a repeated table header, cells cut to their column, the page number in the footer.

use jiff::Timestamp;

use crate::academy::Academy;
use crate::labels::{Label, Locale};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Orientation {
    Portrait,
    Landscape,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrintDocument {
    pub locale: Locale,
    pub orientation: Orientation,
    /// The academy's name, above the title on every page.
    pub academy: String,
    pub title: String,
    pub blocks: Vec<Block>,
    /// Left part of every page's footer, e.g. "Printed on 2026-11-15 10:30 (Europe/Madrid)".
    pub footer: String,
    /// Words of "Page 1 of 2" in the document's language.
    pub page_word: String,
    pub of_word: String,
}

impl PrintDocument {
    /// The frame every sheet shares: a landscape page headed by the academy, the title, the footer "Printed on
    /// 2026-11-15 10:30 (Europe/Madrid)" (the print's instant in the academy's zone) and the page words, all in
    /// the document's language.
    pub fn new(locale: Locale, academy: &Academy, title: Label, blocks: Vec<Block>, printed_at: Timestamp) -> Self {
        let (date, time) = academy.date_and_time(printed_at);
        Self {
            locale,
            orientation: Orientation::Landscape,
            academy: academy.name.clone(),
            title: locale.text(title).to_owned(),
            blocks,
            footer: format!("{} {date} {time} ({})", locale.text(Label::PrintedOn), academy.zone_id()),
            page_word: locale.text(Label::Page).to_owned(),
            of_word: locale.text(Label::PageOf).to_owned(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Block {
    /// One large line, e.g. the final score.
    Headline(String),
    /// Label / value pairs printed side by side.
    Facts(Vec<Fact>),
    Table(Table),
    /// A small line below a table, e.g. "* starter".
    Note(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Fact {
    pub label: String,
    pub value: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Table {
    pub heading: String,
    pub columns: Vec<Column>,
    pub rows: Vec<Row>,
    /// Printed as a single row when `rows` is empty.
    pub empty: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Column {
    pub label: String,
    /// Relative width: the renderer shares the page width by these weights.
    pub weight: u16,
    pub align: Align,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Align {
    Left,
    Right,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Row {
    pub cells: Vec<String>,
    pub style: RowStyle,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RowStyle {
    Normal,
    /// Bold, e.g. the team totals.
    Strong,
    /// Smaller and indented below the row before, e.g. a player's guardian.
    Detail,
}

impl Column {
    pub fn left(label: &str, weight: u16) -> Self {
        Self { label: label.to_owned(), weight, align: Align::Left }
    }

    pub fn right(label: &str, weight: u16) -> Self {
        Self { label: label.to_owned(), weight, align: Align::Right }
    }
}

impl Row {
    pub fn new(style: RowStyle, cells: Vec<String>) -> Self {
        Self { cells, style }
    }
}

impl Fact {
    pub fn new(label: &str, value: impl Into<String>) -> Self {
        Self { label: label.to_owned(), value: value.into() }
    }
}

impl PrintDocument {
    /// Every text of the document in reading order (tests and the renderer's metadata use it).
    pub fn texts(&self) -> Vec<&str> {
        let mut out = vec![self.academy.as_str(), self.title.as_str()];
        for block in &self.blocks {
            match block {
                Block::Headline(text) | Block::Note(text) => out.push(text),
                Block::Facts(facts) => facts.iter().for_each(|f| out.extend([f.label.as_str(), f.value.as_str()])),
                Block::Table(table) => {
                    out.push(&table.heading);
                    out.extend(table.columns.iter().map(|c| c.label.as_str()));
                    out.extend(table.rows.iter().flat_map(|r| r.cells.iter().map(String::as_str)));
                }
            }
        }
        out.push(&self.footer);
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn texts_lists_everything_in_reading_order() {
        let document = PrintDocument {
            locale: Locale::En,
            orientation: Orientation::Landscape,
            academy: "A".into(),
            title: "T".into(),
            blocks: vec![
                Block::Headline("H".into()),
                Block::Facts(vec![Fact::new("L", "V")]),
                Block::Table(Table {
                    heading: "Th".into(),
                    columns: vec![Column::left("C", 1), Column::right("D", 1)],
                    rows: vec![Row::new(RowStyle::Normal, vec!["x".into(), "y".into()])],
                    empty: "none".into(),
                }),
                Block::Note("N".into()),
            ],
            footer: "F".into(),
            page_word: "Page".into(),
            of_word: "of".into(),
        };
        assert_eq!(document.texts(), ["A", "T", "H", "L", "V", "Th", "C", "D", "x", "y", "N", "F"]);
    }
}
