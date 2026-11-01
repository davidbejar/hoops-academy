package com.hoopsacademy.core.domain.eligibility;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.membership.PlayerStatus;
import org.junit.jupiter.api.Test;

class PlayerStatusDerivationTest {

    @Test
    void activeWithoutValidAssignmentBecomesOrphanAndBack() {
        assertThat(PlayerStatusDerivation.derive(PlayerStatus.ACTIVE, false)).isEqualTo(PlayerStatus.ORPHAN);
        assertThat(PlayerStatusDerivation.derive(PlayerStatus.ORPHAN, true)).isEqualTo(PlayerStatus.ACTIVE);
        assertThat(PlayerStatusDerivation.derive(PlayerStatus.ACTIVE, true)).isEqualTo(PlayerStatus.ACTIVE);
    }

    @Test
    void pendingAndWithdrawnPlayersAreLeftAlone() {
        assertThat(PlayerStatusDerivation.derive(PlayerStatus.PENDING_APPROVAL, true)).isEqualTo(PlayerStatus.PENDING_APPROVAL);
        assertThat(PlayerStatusDerivation.derive(PlayerStatus.WITHDRAWN, false)).isEqualTo(PlayerStatus.WITHDRAWN);
        assertThat(PlayerStatusDerivation.derive(PlayerStatus.REJECTED, true)).isEqualTo(PlayerStatus.REJECTED);
    }
}
