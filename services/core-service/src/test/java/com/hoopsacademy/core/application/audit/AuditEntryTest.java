package com.hoopsacademy.core.application.audit;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditRecord;
import com.hoopsacademy.core.application.port.AuditTargetType;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** WP38, decision 16 of 2026-11-06: an academy sees that the platform acted, not which login did. */
class AuditEntryTest {

    private static final UUID PERSON = UUID.randomUUID();

    @Test
    void aPlatformActorIsMaskedForTheAcademy() {
        AuditEntry.Actor actor = AuditEntry.Actor.of(row("platform-admin", Optional.empty()), Optional.empty());

        assertThat(actor.kind()).isEqualTo(AuditActorKind.PLATFORM);
        assertThat(actor.subject()).contains("platform-admin");
        AuditEntry.Actor masked = actor.maskedForAcademy();
        assertThat(masked.kind()).isEqualTo(AuditActorKind.PLATFORM);
        assertThat(masked.subject()).isEmpty();
        assertThat(masked.person()).isEmpty();
        assertThat(masked.name()).isEmpty();
    }

    @Test
    void membersAndBackgroundJobsAreShownAsStored() {
        AuditEntry.Actor member = AuditEntry.Actor.of(row("ada", Optional.of(PERSON)), Optional.of("Ada Admin"));
        AuditEntry.Actor job = AuditEntry.Actor.of(row("system", Optional.empty()), Optional.empty());

        assertThat(member.maskedForAcademy()).isEqualTo(member);
        assertThat(member.subject()).contains("ada");
        assertThat(member.person()).contains(PERSON);
        assertThat(member.name()).contains("Ada Admin");
        assertThat(job.maskedForAcademy()).isEqualTo(job);
        assertThat(job.kind()).isEqualTo(AuditActorKind.SYSTEM);
    }

    private static AuditRecord row(String subject, Optional<UUID> person) {
        return new AuditRecord(UUID.randomUUID(), new TenantId(UUID.randomUUID()), Instant.EPOCH,
                AuditAction.TENANT_SUSPENDED, subject, person, AuditTargetType.TENANT, UUID.randomUUID().toString(),
                Map.of("reason", "Unpaid fees"));
    }
}
