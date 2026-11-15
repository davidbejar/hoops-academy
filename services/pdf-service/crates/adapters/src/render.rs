//! The PDF renderer (driven adapter of [`PdfRenderer`], ADR-0052): draws a [`PrintDocument`] with krilla on A4 in
//! the bundled Roboto fonts (`fonts/`, Apache-2.0, see `THIRD_PARTY.md`). Fixed layout only: no caller markup, fonts,
//! images or URLs reach it, and it fetches nothing. Tables flow over pages with their heading and header row repeated;
//! a cell longer than its column is cut with "…"; every page has the academy, the title, the footer and "Page n of m".
//! The output depends only on the document: no creation date, no random id (the footer carries the printing time).

use krilla::Document;
use krilla::color::luma;
use krilla::geom::{PathBuilder, Point, Rect};
use krilla::metadata::Metadata;
use krilla::page::PageSettings;
use krilla::paint::{Fill, Stroke};
use krilla::surface::Surface;
use krilla::text::{Font, TextDirection};
use pdf_application::{PdfRenderer, RenderError};
use pdf_domain::{Align, Block, Orientation, PrintDocument, RowStyle, Table};
use skrifa::instance::{LocationRef, Size};
use skrifa::{FontRef, MetadataProvider};

static REGULAR: &[u8] = include_bytes!("../../../fonts/Roboto-Regular.ttf");
static BOLD: &[u8] = include_bytes!("../../../fonts/Roboto-Bold.ttf");

const A4_SHORT: f32 = 595.0;
const A4_LONG: f32 = 842.0;
const MARGIN: f32 = 36.0;
const CELL_PAD: f32 = 3.0;
const ELLIPSIS: char = '…';

/// Font size and line height of each kind of line.
#[derive(Debug, Clone, Copy)]
struct Style {
    size: f32,
    height: f32,
    bold: bool,
    grey: bool,
}

const ACADEMY: Style = Style { size: 9.0, height: 13.0, bold: false, grey: true };
const TITLE: Style = Style { size: 15.0, height: 22.0, bold: true, grey: false };
const HEADLINE: Style = Style { size: 13.0, height: 20.0, bold: true, grey: false };
const FACT_LABEL: Style = Style { size: 8.5, height: 13.0, bold: true, grey: false };
const FACT_VALUE: Style = Style { size: 8.5, height: 13.0, bold: false, grey: false };
const HEADING: Style = Style { size: 10.0, height: 18.0, bold: true, grey: false };
const HEADER_CELL: Style = Style { size: 7.5, height: 13.0, bold: true, grey: false };
const CELL: Style = Style { size: 8.0, height: 12.5, bold: false, grey: false };
const STRONG_CELL: Style = Style { size: 8.0, height: 12.5, bold: true, grey: false };
const DETAIL_CELL: Style = Style { size: 7.0, height: 10.5, bold: false, grey: true };
const NOTE: Style = Style { size: 7.0, height: 12.0, bold: false, grey: true };
const FOOTER: Style = Style { size: 7.0, height: 10.0, bold: false, grey: true };
const DETAIL_INDENT: f32 = 8.0;
const BLOCK_GAP: f32 = 8.0;

/// One thing to draw on a page.
#[derive(Debug, Clone)]
enum Op {
    Text { x: f32, baseline: f32, style: Style, text: String },
    Rule { y: f32 },
    Shade { y: f32, height: f32 },
}

/// A font for drawing (krilla) and for measuring (skrifa).
struct Face {
    font: Font,
    measure: FontRef<'static>,
    units_per_em: f32,
}

impl Face {
    fn new(bytes: &'static [u8]) -> Result<Self, RenderError> {
        let font = Font::new(bytes.into(), 0).ok_or_else(|| RenderError("bundled font unreadable".into()))?;
        let measure = FontRef::new(bytes).map_err(|_| RenderError("bundled font unreadable".into()))?;
        let units_per_em = f32::from(measure.metrics(Size::unscaled(), LocationRef::default()).units_per_em);
        Ok(Self { font, measure, units_per_em })
    }

    fn width(&self, text: &str, size: f32) -> f32 {
        let charmap = self.measure.charmap();
        let metrics = self.measure.glyph_metrics(Size::unscaled(), LocationRef::default());
        let units: f32 = text
            .chars()
            .map(|ch| charmap.map(ch).and_then(|glyph| metrics.advance_width(glyph)).unwrap_or(self.units_per_em / 2.0))
            .sum();
        units * size / self.units_per_em
    }
}

/// The krilla renderer with the bundled fonts.
pub struct KrillaRenderer {
    regular: Face,
    bold: Face,
}

impl std::fmt::Debug for KrillaRenderer {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("KrillaRenderer")
    }
}

impl KrillaRenderer {
    pub fn new() -> Result<Self, RenderError> {
        Ok(Self { regular: Face::new(REGULAR)?, bold: Face::new(BOLD)? })
    }

    fn face(&self, style: Style) -> &Face {
        if style.bold { &self.bold } else { &self.regular }
    }

    fn width(&self, text: &str, style: Style) -> f32 {
        self.face(style).width(text, style.size)
    }

    /// `text` cut with "…" so that it fits `max` points.
    fn fit(&self, text: &str, style: Style, max: f32) -> String {
        if self.width(text, style) <= max {
            return text.to_owned();
        }
        let mut cut: String = text.to_owned();
        while !cut.is_empty() {
            cut.pop();
            let candidate = format!("{}{ELLIPSIS}", cut.trim_end());
            if self.width(&candidate, style) <= max {
                return candidate;
            }
        }
        String::new()
    }
}

/// The pages of a document as lists of drawing operations, before the page numbers are known.
struct Layout<'a> {
    renderer: &'a KrillaRenderer,
    document: &'a PrintDocument,
    width: f32,
    height: f32,
    pages: Vec<Vec<Op>>,
    y: f32,
}

impl<'a> Layout<'a> {
    fn new(renderer: &'a KrillaRenderer, document: &'a PrintDocument) -> Self {
        let (width, height) = match document.orientation {
            Orientation::Landscape => (A4_LONG, A4_SHORT),
            Orientation::Portrait => (A4_SHORT, A4_LONG),
        };
        let mut layout = Self { renderer, document, width, height, pages: Vec::new(), y: 0.0 };
        layout.new_page();
        layout
    }

    fn content_width(&self) -> f32 {
        self.width - 2.0 * MARGIN
    }

    fn bottom(&self) -> f32 {
        self.height - MARGIN - FOOTER.height - 4.0
    }

    fn ops(&mut self) -> &mut Vec<Op> {
        let last = self.pages.len() - 1;
        &mut self.pages[last]
    }

    fn new_page(&mut self) {
        self.pages.push(Vec::new());
        self.y = MARGIN;
        let academy = self.renderer.fit(&self.document.academy, ACADEMY, self.content_width());
        self.line(MARGIN, ACADEMY, academy);
        let title = self.renderer.fit(&self.document.title, TITLE, self.content_width());
        self.line(MARGIN, TITLE, title);
        self.y += 4.0;
    }

    /// Writes one line at the cursor and moves it down by the style's height.
    fn line(&mut self, x: f32, style: Style, text: String) {
        let baseline = self.y + style.size;
        self.ops().push(Op::Text { x, baseline, style, text });
        self.y += style.height;
    }

    /// Starts a new page unless `needed` points still fit on this one.
    fn room(&mut self, needed: f32) -> bool {
        if self.y + needed > self.bottom() {
            self.new_page();
            return true;
        }
        false
    }

    fn block(&mut self, block: &Block) {
        match block {
            Block::Headline(text) => {
                self.room(HEADLINE.height);
                let text = self.renderer.fit(text, HEADLINE, self.content_width());
                self.line(MARGIN, HEADLINE, text);
            }
            Block::Note(text) => {
                self.room(NOTE.height);
                let text = self.renderer.fit(text, NOTE, self.content_width());
                self.line(MARGIN, NOTE, text);
            }
            Block::Facts(facts) => self.facts(facts),
            Block::Table(table) => self.table(table),
        }
        self.y += BLOCK_GAP;
    }

    /// "Label value" pairs side by side, wrapped onto the next line when the line is full.
    fn facts(&mut self, facts: &[pdf_domain::Fact]) {
        self.room(FACT_VALUE.height);
        let mut x = MARGIN;
        let right = MARGIN + self.content_width();
        for fact in facts {
            let label = format!("{}:", fact.label);
            let label_width = self.renderer.width(&label, FACT_LABEL) + 3.0;
            let value = self.renderer.fit(&fact.value, FACT_VALUE, self.content_width() - label_width);
            let width = label_width + self.renderer.width(&value, FACT_VALUE) + 14.0;
            if x > MARGIN && x + width > right {
                x = MARGIN;
                self.y += FACT_VALUE.height;
                self.room(FACT_VALUE.height);
            }
            let baseline = self.y + FACT_VALUE.size;
            self.ops().push(Op::Text { x, baseline, style: FACT_LABEL, text: label });
            self.ops().push(Op::Text { x: x + label_width, baseline, style: FACT_VALUE, text: value });
            x += width;
        }
        self.y += FACT_VALUE.height;
    }

    fn columns(&self, table: &Table) -> Vec<(f32, f32)> {
        let total: f32 = table.columns.iter().map(|c| f32::from(c.weight)).sum::<f32>().max(1.0);
        let mut x = MARGIN;
        table
            .columns
            .iter()
            .map(|column| {
                let width = self.content_width() * f32::from(column.weight) / total;
                let start = x;
                x += width;
                (start, width)
            })
            .collect()
    }

    fn table_header(&mut self, table: &Table, columns: &[(f32, f32)]) {
        let heading = self.renderer.fit(&table.heading, HEADING, self.content_width());
        self.line(MARGIN, HEADING, heading);
        let y = self.y;
        self.ops().push(Op::Shade { y, height: HEADER_CELL.height });
        let cells: Vec<String> = table.columns.iter().map(|c| c.label.clone()).collect();
        self.cells(table, columns, &cells, HEADER_CELL, 0.0);
        let y = self.y;
        self.ops().push(Op::Rule { y });
    }

    fn table(&mut self, table: &Table) {
        let columns = self.columns(table);
        self.room(HEADING.height + HEADER_CELL.height + CELL.height);
        self.table_header(table, &columns);
        if table.rows.is_empty() {
            let empty = self.renderer.fit(&table.empty, CELL, self.content_width());
            self.line(MARGIN + CELL_PAD, CELL, empty);
        }
        for row in &table.rows {
            let (style, indent) = match row.style {
                RowStyle::Normal => (CELL, 0.0),
                RowStyle::Strong => (STRONG_CELL, 0.0),
                RowStyle::Detail => (DETAIL_CELL, DETAIL_INDENT),
            };
            if self.room(style.height) {
                self.table_header(table, &columns);
            }
            if row.style == RowStyle::Strong {
                let y = self.y;
                self.ops().push(Op::Rule { y });
            }
            self.cells(table, &columns, &row.cells, style, indent);
        }
    }

    fn cells(&mut self, table: &Table, columns: &[(f32, f32)], cells: &[String], style: Style, indent: f32) {
        let baseline = self.y + style.size + (style.height - style.size) / 2.0 - 1.0;
        for ((column, (x, width)), text) in table.columns.iter().zip(columns).zip(cells) {
            let room = width - 2.0 * CELL_PAD - indent;
            let text = self.renderer.fit(text, style, room);
            let x = match column.align {
                Align::Left => x + CELL_PAD + indent,
                Align::Right => x + width - CELL_PAD - self.renderer.width(&text, style),
            };
            self.ops().push(Op::Text { x, baseline, style, text });
        }
        self.y += style.height;
    }

    /// The footer of every page: the document's footer on the left, "Page n of m" on the right.
    fn footers(&mut self) {
        let count = self.pages.len();
        let baseline = self.height - MARGIN;
        let footer = self.renderer.fit(&self.document.footer, FOOTER, self.content_width() * 0.75);
        for (index, ops) in self.pages.iter_mut().enumerate() {
            let number = format!("{} {} {} {count}", self.document.page_word, index + 1, self.document.of_word);
            let x = self.width - MARGIN - self.renderer.width(&number, FOOTER);
            ops.push(Op::Text { x: MARGIN, baseline, style: FOOTER, text: footer.clone() });
            ops.push(Op::Text { x, baseline, style: FOOTER, text: number });
        }
    }
}

impl KrillaRenderer {
    fn draw(&self, surface: &mut Surface<'_>, ops: &[Op], width: f32) {
        for op in ops {
            match op {
                Op::Text { x, baseline, style, text } => {
                    if text.is_empty() {
                        continue;
                    }
                    let shade = if style.grey { 90 } else { 0 };
                    surface.set_fill(Some(Fill { paint: luma::Color::new(shade).into(), ..Fill::default() }));
                    surface.draw_text(
                        Point::from_xy(*x, *baseline),
                        self.face(*style).font.clone(),
                        style.size,
                        text,
                        false,
                        TextDirection::Auto,
                    );
                }
                Op::Rule { y } => {
                    let mut path = PathBuilder::new();
                    path.move_to(MARGIN, *y);
                    path.line_to(width - MARGIN, *y);
                    if let Some(path) = path.finish() {
                        surface.set_fill(None);
                        surface.set_stroke(Some(Stroke {
                            paint: luma::Color::new(150).into(),
                            width: 0.5,
                            ..Stroke::default()
                        }));
                        surface.draw_path(&path);
                        surface.set_stroke(None);
                    }
                }
                Op::Shade { y, height } => {
                    let mut path = PathBuilder::new();
                    if let Some(rect) = Rect::from_xywh(MARGIN, *y, width - 2.0 * MARGIN, *height) {
                        path.push_rect(rect);
                    }
                    if let Some(path) = path.finish() {
                        surface.set_fill(Some(Fill { paint: luma::Color::new(235).into(), ..Fill::default() }));
                        surface.draw_path(&path);
                    }
                }
            }
        }
    }
}

impl PdfRenderer for KrillaRenderer {
    fn render(&self, document: &PrintDocument) -> Result<Vec<u8>, RenderError> {
        let mut layout = Layout::new(self, document);
        for block in &document.blocks {
            layout.block(block);
        }
        layout.footers();
        let (width, height, pages) = (layout.width, layout.height, layout.pages);

        let mut pdf = Document::new();
        pdf.set_metadata(
            Metadata::new()
                .title(format!("{} – {}", document.title, document.academy))
                .language(document.locale.code().to_owned())
                .creator("Hoops Academy pdf-service".to_owned()),
        );
        for ops in &pages {
            let settings = PageSettings::from_wh(width, height).ok_or_else(|| RenderError("page size".into()))?;
            let mut page = pdf.start_page_with(settings);
            let mut surface = page.surface();
            self.draw(&mut surface, ops, width);
            surface.finish();
            page.finish();
        }
        // krilla's error may quote a glyph of the document: only its kind reaches the log
        pdf.finish().map_err(|_| RenderError("krilla could not write the document".into()))
    }
}
