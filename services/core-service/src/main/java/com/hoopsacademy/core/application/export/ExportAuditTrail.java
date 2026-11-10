package com.hoopsacademy.core.application.export;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.audit.AuditEntry;
import com.hoopsacademy.core.application.audit.ReadAuditTrail;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.AuditLog;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * GET /api/core/audit-events:export (ADMIN; decisions 67 and 68, ADR-0048): every row the academy's list returns for
 * the same filter, with its names and the masking of the platform actor ({@link ReadAuditTrail}), then the audit row
 * {@code audit.exported} (the row count and the filter; written after the read, so never in its own file).
 */
@ApplicationScoped
public class ExportAuditTrail {

    private final ReadAuditTrail trail;
    private final ExportOrigins origins;
    private final TenantContext tenantContext;
    private final AuditLog audit;

    public ExportAuditTrail(ReadAuditTrail trail, ExportOrigins origins, TenantContext tenantContext, AuditLog audit) {
        this.trail = trail;
        this.origins = origins;
        this.tenantContext = tenantContext;
        this.audit = audit;
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public AuditSheet export(AuditFilter filter) {
        List<AuditEntry> entries = ExportPages.readAll(page -> trail.list(filter, page), entry -> entry.record().id());
        ExportOrigin origin = origins.current();
        audit.record(AuditEvent.of(AuditAction.AUDIT_EXPORTED, tenantContext.requireTenantId().value(),
                metadata(filter, entries.size())));
        return new AuditSheet(origin, entries.stream().map(entry -> new AuditSheet.Line(entry, origin.zone(), null))
                .toList());
    }

    /** The row count and the filter as given: instants and action names, never personal data. */
    static Map<String, Object> metadata(AuditFilter filter, int rows) {
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("rows", rows);
        filter.from().ifPresent(from -> metadata.put("from", from.toString()));
        filter.to().ifPresent(to -> metadata.put("to", to.toString()));
        if (!filter.actions().isEmpty()) {
            metadata.put("actions", filter.actions().stream().map(AuditAction::wireName).sorted().toList());
        }
        return metadata;
    }
}
