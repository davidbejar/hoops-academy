package com.hoopsacademy.core.application.export;

import java.util.Locale;

/** The file a roster export answers (WP116): the CSV of ADR-0048 or the printed sheet. */
public enum ExportFormat {
    CSV,
    PDF;

    /** As recorded in the audit row's {@code format}. */
    public String code() {
        return name().toLowerCase(Locale.ROOT);
    }
}
