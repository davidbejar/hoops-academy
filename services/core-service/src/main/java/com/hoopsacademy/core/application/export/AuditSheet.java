package com.hoopsacademy.core.application.export;

import com.hoopsacademy.core.application.audit.AuditEntry;
import java.time.ZoneId;
import java.util.List;

/** The content of an audit trail export (ADR-0048): the entries, newest first, each with its academy's zone. */
public record AuditSheet(ExportOrigin origin, List<Line> lines) {

    /** An entry, the time zone of its academy and, on the platform path, the academy's name ({@code null} else). */
    public record Line(AuditEntry entry, ZoneId zone, String academyName) {}

    public AuditSheet {
        lines = List.copyOf(lines);
    }
}
