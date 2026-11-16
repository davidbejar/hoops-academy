package com.hoopsacademy.core.adapters.in.export;

import com.hoopsacademy.core.application.export.ExportFormat;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

/**
 * The form of the roster export the caller asked for (WP116, ADR-0048 amendment): the first acceptable media type,
 * in the caller's order of preference, that is the CSV or the PDF decides; a wildcard that covers both means the CSV,
 * as does no {@code Accept} at all, so every client of core 3.6 keeps its file.
 */
public final class AcceptedFormat {

    public static final MediaType CSV = MediaType.valueOf("text/csv");
    public static final MediaType PDF = MediaType.valueOf("application/pdf");

    private AcceptedFormat() {}

    /** @param acceptable the {@code Accept} entries, most preferred first (as JAX-RS sorts them) */
    public static ExportFormat of(List<MediaType> acceptable) {
        for (MediaType type : acceptable) {
            if (type.isCompatible(CSV)) {
                return ExportFormat.CSV;
            }
            if (type.isCompatible(PDF)) {
                return ExportFormat.PDF;
            }
        }
        return ExportFormat.CSV;
    }
}
