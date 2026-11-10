package com.hoopsacademy.core.application.export;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.audit.PlatformAuditEntry;
import com.hoopsacademy.core.application.audit.ReadPlatformAuditTrail;
import com.hoopsacademy.core.application.platform.PlatformTenantQueries;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.PlatformAuditLog;
import com.hoopsacademy.core.domain.tenant.Tenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * GET /platform/audit-events:export (super_admin; decisions 67 and 68, ADR-0048): every row the platform list returns
 * for the same academy and filter, with its names ({@link ReadPlatformAuditTrail}: academies and their active
 * administrators only) and each row's time in its academy's zone. The export is recorded as {@code audit.exported} in
 * the trail of the academy given, or of each academy with rows in the file (its own row count).
 */
@ApplicationScoped
public class ExportPlatformAuditTrail {

    private final ReadPlatformAuditTrail trail;
    private final PlatformTenantQueries registry;
    private final ExportOrigins origins;
    private final PlatformAuditLog audit;

    public ExportPlatformAuditTrail(ReadPlatformAuditTrail trail, PlatformTenantQueries registry,
            ExportOrigins origins, PlatformAuditLog audit) {
        this.trail = trail;
        this.registry = registry;
        this.origins = origins;
        this.audit = audit;
    }

    @Transactional
    public AuditSheet export(Optional<TenantId> tenant, AuditFilter filter) {
        Optional<Tenant> academy = tenant.map(registry::get);
        List<PlatformAuditEntry> entries = ExportPages.readAll(page -> trail.list(tenant, filter, page),
                entry -> entry.entry().record().id());
        Map<TenantId, Long> rowsPerAcademy = entries.stream().collect(Collectors.groupingBy(
                entry -> entry.entry().record().tenant(), LinkedHashMap::new, Collectors.counting()));
        Map<TenantId, Tenant> academies = rowsPerAcademy.keySet().stream()
                .collect(Collectors.toMap(id -> id, registry::get));
        tenant.ifPresentOrElse(id -> record(id, filter, entries.size()),
                () -> rowsPerAcademy.forEach((id, rows) -> record(id, filter, rows)));
        return new AuditSheet(academy.map(origins::of).orElseGet(origins::platform), entries.stream()
                .map(entry -> new AuditSheet.Line(entry.entry(),
                        academies.get(entry.entry().record().tenant()).timezone(), entry.tenantName()))
                .toList());
    }

    private void record(TenantId tenant, AuditFilter filter, long rows) {
        audit.record(tenant, AuditEvent.of(AuditAction.AUDIT_EXPORTED, tenant.value(),
                ExportAuditTrail.metadata(filter, Math.toIntExact(rows))));
    }
}
