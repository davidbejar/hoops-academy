package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.core.application.audit.AuditEntry;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditFilter;
import com.hoopsacademy.core.application.port.AuditRecord;
import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Contract {@code AuditActor}, {@code AuditTarget} and the shared query parameters of both audit lists. */
public final class AuditDtos {

    private AuditDtos() {}

    /** Contract {@code AuditActor}. */
    public record ActorDto(String kind, String subject, UUID personId, String displayName) {}

    /** Contract {@code AuditTarget}. */
    public record TargetDto(String type, String id, String displayName) {}

    /** The fields of contract {@code AuditEvent}, shared with {@code PlatformAuditEvent}. */
    public record EventFields(UUID id, Instant at, String action, ActorDto actor, TargetDto target,
            Map<String, Object> metadata) {

        public static EventFields of(AuditEntry entry) {
            AuditRecord record = entry.record();
            return new EventFields(record.id(), record.at(), record.action().wireName(),
                    new ActorDto(entry.actorKind().name(), record.actorSubject(), record.actorPerson().orElse(null),
                            entry.actorName().orElse(null)),
                    new TargetDto(record.targetType().wireName(), record.targetId(), entry.targetName().orElse(null)),
                    record.metadata());
        }
    }

    /** {@code from} / {@code to} (RFC 3339, from before to) and {@code action} (wire names); 400 otherwise. */
    public static AuditFilter filter(String rawFrom, String rawTo, List<String> rawActions) {
        Optional<Instant> from = Params.instant("from", rawFrom);
        Optional<Instant> to = Params.instant("to", rawTo);
        if (from.isPresent() && to.isPresent() && !from.get().isBefore(to.get())) {
            throw InvalidRequestException.of("from", "must be before to");
        }
        Set<AuditAction> actions = EnumSet.noneOf(AuditAction.class);
        for (String action : rawActions == null ? List.<String>of() : rawActions) {
            actions.add(AuditAction.fromWireName(action)
                    .orElseThrow(() -> InvalidRequestException.of("action", "unknown action")));
        }
        return new AuditFilter(from, to, actions);
    }
}
