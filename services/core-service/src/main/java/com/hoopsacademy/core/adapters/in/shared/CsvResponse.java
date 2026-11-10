package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.core.adapters.in.export.CsvDocument;
import com.hoopsacademy.core.adapters.in.export.ExportFileName;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;

/** The download of a CSV export (ADR-0048): the file, its name as an attachment, never cached. */
public final class CsvResponse {

    /** {@code Accept-Language}: the language of the export's labels. */
    public static final String ACCEPT_LANGUAGE = "Accept-Language";

    private CsvResponse() {}

    public static Response of(byte[] file, String fileName) {
        return Response.ok(file, CsvDocument.MEDIA_TYPE)
                .header(HttpHeaders.CONTENT_DISPOSITION, ExportFileName.attachment(fileName))
                .header(HttpHeaders.CACHE_CONTROL, "no-store").build();
    }
}
