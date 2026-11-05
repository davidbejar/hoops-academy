package com.hoopsacademy.core.application.audit;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AuditActorKindTest {

    @Test
    void aStoredPersonIsAMemberOfTheAcademy() {
        assertThat(AuditActorKind.of("sub", Optional.of(UUID.randomUUID()))).isEqualTo(AuditActorKind.PERSON);
    }

    @Test
    void theSystemSubjectIsABackgroundJob() {
        assertThat(AuditActorKind.of("system", Optional.empty())).isEqualTo(AuditActorKind.SYSTEM);
    }

    @Test
    void anyOtherLoginWithoutPersonActedFromThePlatform() {
        assertThat(AuditActorKind.of("platform-admin", Optional.empty())).isEqualTo(AuditActorKind.PLATFORM);
    }
}
