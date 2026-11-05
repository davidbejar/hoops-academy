package com.hoopsacademy.core.application.port;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.time.Instant;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;

class AuditFilterTest {

    private static final Instant T = Instant.parse("2026-03-01T10:00:00Z");

    @Test
    void fromMustBeBeforeTo() {
        assertThatIllegalArgumentException().isThrownBy(() -> new AuditFilter(Optional.of(T), Optional.of(T), Set.of()));
        assertThatIllegalArgumentException()
                .isThrownBy(() -> new AuditFilter(Optional.of(T.plusSeconds(1)), Optional.of(T), Set.of()));
        assertThat(new AuditFilter(Optional.of(T), Optional.of(T.plusSeconds(1)), Set.of()).from()).contains(T);
    }

    @Test
    void openBoundsAndNoActionsMeanEverything() {
        AuditFilter all = AuditFilter.all();
        assertThat(all.from()).isEmpty();
        assertThat(all.to()).isEmpty();
        assertThat(all.actions()).isEmpty();
    }

    @Test
    void theActionsAreCopied() {
        Set<AuditAction> actions = new HashSet<>(Set.of(AuditAction.MEMBER_INVITED));
        AuditFilter filter = new AuditFilter(Optional.empty(), Optional.empty(), actions);
        actions.add(AuditAction.TENANT_CREATED);
        assertThat(filter.actions()).containsExactly(AuditAction.MEMBER_INVITED);
    }
}
