package com.hoopsacademy.core.application.audit;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.platform.PlatformTenantQueries;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.AuditNames;
import com.hoopsacademy.core.application.port.AuditRecord;
import com.hoopsacademy.core.application.port.AuditTargetType;
import com.hoopsacademy.core.application.port.PlatformAuditTrail;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * GET /platform/audit-events (super_admin): the trail of every academy, or of one (404 when unknown), read through the
 * platform datasource (ADR-0029). Names stay within what the platform already manages: the academy (registry) and
 * persons who are active administrators of their academy (ADR-0023), looked up per academy as core_app inside
 * {@code TenantScope.runAs}, i.e. under that academy's RLS. Other persons and players are shown by id only.
 */
@ApplicationScoped
public class ReadPlatformAuditTrail {

    private final PlatformTenantQueries registry;
    private final PlatformAuditTrail trail;
    private final AuditNames names;
    private final TenantScope tenantScope;

    public ReadPlatformAuditTrail(PlatformTenantQueries registry, PlatformAuditTrail trail, AuditNames names,
            TenantScope tenantScope) {
        this.registry = registry;
        this.trail = trail;
        this.names = names;
        this.tenantScope = tenantScope;
    }

    @Transactional
    public PageResult<PlatformAuditEntry> list(Optional<TenantId> tenant, AuditFilter filter, PageRequest page) {
        tenant.ifPresent(registry::get);
        PageResult<PlatformAuditTrail.Row> rows = trail.list(tenant, filter, page);
        Map<TenantId, Map<UUID, String>> admins = adminNames(rows);
        return rows.map(row -> entry(row, admins.getOrDefault(row.record().tenant(), Map.of())));
    }

    private Map<TenantId, Map<UUID, String>> adminNames(PageResult<PlatformAuditTrail.Row> rows) {
        Map<TenantId, Set<UUID>> persons = new HashMap<>();
        for (PlatformAuditTrail.Row row : rows.items()) {
            AuditRecord record = row.record();
            Set<UUID> ids = persons.computeIfAbsent(record.tenant(), t -> new HashSet<>());
            record.actorPerson().ifPresent(ids::add);
            if (record.targetType() == AuditTargetType.PERSON) {
                record.targetUuid().ifPresent(ids::add);
            }
        }
        Map<TenantId, Map<UUID, String>> admins = new HashMap<>();
        persons.forEach((tenant, ids) -> {
            if (!ids.isEmpty()) {
                admins.put(tenant, tenantScope.runAs(tenant, () -> names.activeAdmins(ids)));
            }
        });
        return admins;
    }

    private static PlatformAuditEntry entry(PlatformAuditTrail.Row row, Map<UUID, String> admins) {
        AuditRecord record = row.record();
        Optional<String> target = switch (record.targetType()) {
            case PERSON -> record.targetUuid().map(admins::get);
            case TENANT -> record.targetUuid().filter(id -> id.equals(record.tenant().value()))
                    .map(id -> row.tenantName());
            default -> Optional.empty();
        };
        return new PlatformAuditEntry(new AuditEntry(record, AuditActorKind.of(record.actorSubject(),
                record.actorPerson()), record.actorPerson().map(admins::get), target), row.tenantName());
    }
}
