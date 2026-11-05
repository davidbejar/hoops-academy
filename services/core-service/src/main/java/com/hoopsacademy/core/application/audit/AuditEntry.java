package com.hoopsacademy.core.application.audit;

import com.hoopsacademy.core.application.port.AuditRecord;
import java.util.Optional;

/** One audit row with the names resolved at read time (absent when not resolvable or not shown). */
public record AuditEntry(AuditRecord record, AuditActorKind actorKind, Optional<String> actorName,
        Optional<String> targetName) {}
