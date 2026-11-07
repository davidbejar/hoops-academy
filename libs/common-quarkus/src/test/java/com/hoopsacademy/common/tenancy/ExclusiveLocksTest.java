package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import org.junit.jupiter.api.Test;

/** The pure rules of {@link TenantScope#runExclusive} (PIT scope, WP88): lock keys and the lock transaction timeout. */
class ExclusiveLocksTest {

    @Test
    void aLockNameMapsToTheFirstEightBytesOfItsSha256() {
        assertThat(ExclusiveLocks.advisoryKey("athlete.materialisation")).isEqualTo(-8852242366011214926L);
        assertThat(ExclusiveLocks.advisoryKey("core.eligibility-sweep")).isEqualTo(5448932772600865638L);
    }

    @Test
    void tenantScopeUsesTheSameKeys() {
        assertThat(TenantScope.advisoryKey("athlete.materialisation"))
                .isEqualTo(ExclusiveLocks.advisoryKey("athlete.materialisation"));
    }

    @Test
    void theLockTransactionTimeoutIsTheDurationInWholeSeconds() {
        assertThat(ExclusiveLocks.transactionTimeoutSeconds(Duration.ofHours(6))).isEqualTo(21_600);
        assertThat(ExclusiveLocks.transactionTimeoutSeconds(Duration.ofMillis(2_999))).isEqualTo(2);
    }

    @Test
    void aTimeoutBeyondWhatJtaTakesIsCappedAtItsMaximum() {
        assertThat(ExclusiveLocks.transactionTimeoutSeconds(Duration.ofSeconds(Integer.MAX_VALUE + 1L)))
                .isEqualTo(Integer.MAX_VALUE);
        assertThat(ExclusiveLocks.transactionTimeoutSeconds(Duration.ofSeconds(Integer.MAX_VALUE)))
                .isEqualTo(Integer.MAX_VALUE);
    }
}
