package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.core.adapters.in.export.CsvDocument;
import com.hoopsacademy.core.adapters.in.export.ExportFileName;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;

/** The download of an export (ADR-0048): the file, its name as an attachment, never cached. */
public final class ExportResponse {

    /** {@code Accept-Language}: the language of the export's labels. */
    public static final String ACCEPT_LANGUAGE = "Accept-Language";

    private ExportResponse() {}

    /** A CSV file ({@code text/csv; charset=utf-8}). */
    public static Response csv(byte[] file, String fileName) {
        return of(file, CsvDocument.MEDIA_TYPE, fileName);
    }

    /** Any export file (WP116: the printed roster, {@code application/pdf}). */
    public static Response of(byte[] file, String mediaType, String fileName) {
        return Response.ok(file, mediaType)
                .header(HttpHeaders.CONTENT_DISPOSITION, ExportFileName.attachment(fileName))
                .header(HttpHeaders.CACHE_CONTROL, "no-store").build();
    }
}
