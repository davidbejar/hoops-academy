//! The PDF renderer (driven adapter of [`PdfRenderer`], ADR-0052): draws a [`PrintDocument`] with krilla.

use pdf_application::{PdfRenderer, RenderError};
use pdf_domain::PrintDocument;

/// The krilla renderer with the bundled fonts.
#[derive(Debug)]
pub struct KrillaRenderer;

impl KrillaRenderer {
    pub fn new() -> Result<Self, RenderError> {
        Ok(Self)
    }
}

impl PdfRenderer for KrillaRenderer {
    fn render(&self, _document: &PrintDocument) -> Result<Vec<u8>, RenderError> {
        Err(RenderError("not drawn yet".into()))
    }
}
