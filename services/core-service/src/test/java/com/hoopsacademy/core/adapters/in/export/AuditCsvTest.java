package com.hoopsacademy.core.adapters.in.export;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.audit.AuditActorKind;
import com.hoopsacademy.core.application.audit.AuditEntry;
import com.hoopsacademy.core.application.export.AuditSheet;
import com.hoopsacademy.core.application.export.ExportOrigin;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditRecord;
import com.hoopsacademy.core.application.port.AuditTargetType;
import com.hoopsacademy.core.domain.shared.AppLocale;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** ADR-0048: the audit file — local date, time and zone in their own columns, labels plus codes, metadata pairs. */
class AuditCsvTest {

    private static final TenantId TENANT = TenantId.parse("0190b6a0-0000-7000-8000-0000000000aa");
    private static final UUID PERSON = UUID.fromString("0190b6a0-0000-7000-8000-000000000001");
    private static final UUID TARGET = UUID.fromString("0190b6a0-0000-7000-8000-000000000002");
    private static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");
    private static final ExportOrigin ORIGIN = new ExportOrigin("hangtuah", JAKARTA, LocalDate.of(2026, 11, 10));

    @Test
    void anAcademyFileShowsLocalTimesLabelsCodesAndTheMetadata() {
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("roles", List.of("PARENT", "PLAYER"));
        metadata.put("login", true);
        metadata.put("note", null);
        AuditEntry invited = entry(Instant.parse("2026-11-09T17:30:59Z"), AuditAction.MEMBER_INVITED,
                new AuditEntry.Actor(AuditActorKind.PERSON, Optional.of("sub-1"), Optional.of(PERSON),
                        Optional.of("Ada Admin")), Optional.of("Pia Player"), metadata);
        AuditEntry suspended = entry(Instant.parse("2026-11-01T00:00:00Z"), AuditAction.TENANT_SUSPENDED,
                new AuditEntry.Actor(AuditActorKind.PLATFORM, Optional.empty(), Optional.empty(), Optional.empty()),
                Optional.empty(), Map.of("reason", "=unpaid, \"late\""));

        String csv = render(AuditCsv.academy(sheet(invited, suspended), ExportLabels.of(AppLocale.EN)));

        assertThat(csv.split("\r\n")).containsExactly(
                "Date,Time,Time zone,Action,Action code,Actor,Actor name,Actor person id,Actor login,Target,"
                        + "Target id,Target name,Details",
                "2026-11-10,00:30,Asia/Jakarta,Member invited,member.invited,Academy member,Ada Admin," + PERSON
                        + ",sub-1,Person," + TARGET + ",Pia Player,\"login=true; note=; roles=[PARENT, PLAYER]\"",
                "2026-11-01,07:00,Asia/Jakarta,Academy suspended,tenant.suspended,Platform administrator,,,,Person,"
                        + TARGET + ",,\"reason==unpaid, \"\"late\"\"\"");
    }

    @Test
    void thePlatformFileNamesTheAcademyOfEachRowInItsOwnZone() {
        AuditEntry created = entry(Instant.parse("2026-11-09T23:30:00Z"), AuditAction.TENANT_CREATED,
                new AuditEntry.Actor(AuditActorKind.PLATFORM, Optional.of("root"), Optional.empty(),
                        Optional.empty()), Optional.of("Hangtuah"), Map.of("slug", "hangtuah"));
        AuditSheet sheet = new AuditSheet(ORIGIN, List.of(
                new AuditSheet.Line(created, ZoneId.of("Europe/Madrid"), "Hangtuah"),
                new AuditSheet.Line(created, JAKARTA, "-Dewa")));

        String csv = render(AuditCsv.platform(sheet, ExportLabels.of(AppLocale.ES)));

        String[] lines = csv.split("\r\n");
        assertThat(lines[0]).startsWith("Academia,Id de la academia,Fecha,Hora,Zona horaria,Acción,");
        assertThat(lines[1]).startsWith("Hangtuah," + TENANT + ",2026-11-10,00:30,Europe/Madrid,Academia creada,"
                + "tenant.created,Administrador de la plataforma,,,root,");
        assertThat(lines[2]).startsWith("'-Dewa," + TENANT + ",2026-11-10,06:30,Asia/Jakarta,");
        assertThat(lines[1]).endsWith(",slug=hangtuah");
    }

    @Test
    void anEmptyTrailIsTheHeaderOnly() {
        assertThat(render(AuditCsv.academy(new AuditSheet(ORIGIN, List.of()), ExportLabels.of(AppLocale.ID))))
                .startsWith("Tanggal,").endsWith("\r\n").doesNotContain("\r\n2");
    }

    private static AuditSheet sheet(AuditEntry... entries) {
        return new AuditSheet(ORIGIN, java.util.Arrays.stream(entries)
                .map(entry -> new AuditSheet.Line(entry, JAKARTA, null)).toList());
    }

    private static AuditEntry entry(Instant at, AuditAction action, AuditEntry.Actor actor, Optional<String> target,
            Map<String, Object> metadata) {
        AuditRecord record = new AuditRecord(UUID.randomUUID(), TENANT, at, action, "stored-sub", Optional.empty(),
                AuditTargetType.PERSON, TARGET.toString(), metadata);
        return new AuditEntry(record, actor, target);
    }

    private static String render(byte[] bytes) {
        return new String(bytes, 3, bytes.length - 3, StandardCharsets.UTF_8);
    }
}
