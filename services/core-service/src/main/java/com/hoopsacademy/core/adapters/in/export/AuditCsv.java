package com.hoopsacademy.core.adapters.in.export;

import static com.hoopsacademy.core.adapters.in.export.CsvDocument.text;

import com.hoopsacademy.core.adapters.in.export.CsvDocument.Cell;
import com.hoopsacademy.core.application.audit.AuditEntry;
import com.hoopsacademy.core.application.export.AuditSheet;
import com.hoopsacademy.core.application.port.AuditRecord;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * The audit trail file (ADR-0048): date, time and zone of each row in its academy's time zone, the action's label and
 * code, the actor as the JSON read shows it (masked on the academy path), the target and the metadata as sorted
 * {@code key=value} pairs. The platform file starts with the academy's name and id.
 */
public final class AuditCsv {

    private static final List<String> COLUMNS = List.of("audit.date", "audit.time", "audit.timeZone", "audit.action",
            "audit.actionCode", "audit.actor", "audit.actorName", "audit.actorPersonId", "audit.actorLogin",
            "audit.target", "audit.targetId", "audit.targetName", "audit.details");
    private static final List<String> ACADEMY_COLUMNS = List.of("audit.academy", "audit.academyId");
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm");

    private AuditCsv() {}

    /** The academy's own file. */
    public static byte[] academy(AuditSheet sheet, ExportLabels labels) {
        return render(sheet, labels, false);
    }

    /** The super admin's file: every row names its academy. */
    public static byte[] platform(AuditSheet sheet, ExportLabels labels) {
        return render(sheet, labels, true);
    }

    private static byte[] render(AuditSheet sheet, ExportLabels labels, boolean withAcademy) {
        List<String> header = new ArrayList<>(withAcademy ? ACADEMY_COLUMNS : List.of());
        header.addAll(COLUMNS);
        CsvDocument document = new CsvDocument(header.stream().map(labels::text).toList());
        for (AuditSheet.Line line : sheet.lines()) {
            List<Cell> cells = new ArrayList<>();
            if (withAcademy) {
                cells.add(text(line.academyName()));
                cells.add(text(line.entry().record().tenant().toString()));
            }
            cells.addAll(row(line, labels));
            document.row(cells);
        }
        return document.bytes();
    }

    private static List<Cell> row(AuditSheet.Line line, ExportLabels labels) {
        AuditEntry entry = line.entry();
        AuditRecord record = entry.record();
        AuditEntry.Actor actor = entry.actor();
        ZonedDateTime at = record.at().atZone(line.zone());
        return List.of(CsvDocument.date(at.toLocalDate()), text(TIME.format(at)), text(line.zone().getId()),
                text(labels.action(record.action())), text(record.action().wireName()),
                text(labels.actor(actor.kind())), text(actor.name().orElse(null)),
                text(actor.person().map(UUID::toString).orElse(null)), text(actor.subject().orElse(null)),
                text(labels.target(record.targetType())), text(record.targetId()),
                text(entry.targetName().orElse(null)), text(details(record.metadata())));
    }

    /** {@code key=value} pairs sorted by key; ids, enum names, counts and field names only (no personal data). */
    private static String details(Map<String, Object> metadata) {
        return new TreeMap<>(metadata).entrySet().stream()
                .map(e -> e.getKey() + "=" + Objects.toString(e.getValue(), ""))
                .collect(Collectors.joining("; "));
    }
}
