package com.hoopsacademy.core.domain.membership;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Arrays;
import org.junit.jupiter.api.Test;

class PlayerStatusTest {

    @Test
    void onlyPendingAndRejectedPlayersAreAwaitingOrRefused() {
        assertThat(Arrays.stream(PlayerStatus.values()).filter(PlayerStatus::awaitingOrRefused))
                .containsExactlyInAnyOrder(PlayerStatus.PENDING_APPROVAL, PlayerStatus.REJECTED);
    }
}
