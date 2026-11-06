package com.hoopsacademy.core.application.audit;

import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.AuditNames;
import com.hoopsacademy.core.application.port.AuditRecord;
import com.hoopsacademy.core.application.port.AuditTargetType;
import com.hoopsacademy.core.application.port.AuditTrail;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * GET /api/core/audit-events (ADMIN): one page of the bound academy's trail, newest first, with the names of the
 * persons, players and the academy it mentions resolved under the same RLS scope (WP34). Names are read now, never
 * stored: a renamed person shows the new name, a row that no longer exists shows none. The super admin is masked
 * (decision 16 of 2026-11-06, WP38): a PLATFORM actor carries no subject, person or name here, while the metadata
 * (such as the {@code reason} of {@code tenant.suspended}) is returned unchanged.
 */
@ApplicationScoped
public class ReadAuditTrail {

    private final AuditTrail trail;
    private final AuditNames names;

    public ReadAuditTrail(AuditTrail trail, AuditNames names) {
        this.trail = trail;
        this.names = names;
    }

    @Transactional
    public PageResult<AuditEntry> list(AuditFilter filter, PageRequest page) {
        PageResult<AuditRecord> rows = trail.list(filter, page);
        Map<UUID, String> persons = resolve(names::persons, rows, AuditTargetType.PERSON, true);
        Map<UUID, String> players = resolve(names::players, rows, AuditTargetType.PLAYER, false);
        Map<UUID, String> tenants = resolve(names::tenants, rows, AuditTargetType.TENANT, false);
        Map<AuditTargetType, Map<UUID, String>> targets = Map.of(AuditTargetType.PERSON, persons,
                AuditTargetType.PLAYER, players, AuditTargetType.TENANT, tenants);
        return rows.map(row -> new AuditEntry(row,
                AuditEntry.Actor.of(row, row.actorPerson().map(persons::get)).maskedForAcademy(),
                row.targetUuid().map(id -> targets.getOrDefault(row.targetType(), Map.of()).get(id))));
    }

    private static Map<UUID, String> resolve(Function<Set<UUID>, Map<UUID, String>> lookup,
            PageResult<AuditRecord> rows, AuditTargetType type, boolean withActors) {
        Set<UUID> ids = rows.items().stream()
                .flatMap(row -> Stream.concat(withActors ? row.actorPerson().stream() : Stream.empty(),
                        row.targetType() == type ? row.targetUuid().stream() : Stream.empty()))
                .collect(Collectors.toSet());
        return ids.isEmpty() ? Map.of() : lookup.apply(ids);
    }
}
