package com.hoopsacademy.game.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PlayerVisibilityTest {

    static final PlayerId ANA = PlayerId.of(UUID.fromString("00000000-0000-4000-8000-000000000001"));
    static final PlayerId BEA = PlayerId.of(UUID.fromString("00000000-0000-4000-8000-000000000002"));

    @Test
    void everyoneSeesEveryPlayer() {
        assertThat(PlayerVisibility.everyone().seesAll()).isTrue();
        assertThat(PlayerVisibility.everyone().sees(ANA)).isTrue();
        assertThat(PlayerVisibility.everyone().sees(BEA)).isTrue();
    }

    @Test
    void onlySomePlayersSeesThoseAndNoOneElse() {
        PlayerVisibility onlyAna = PlayerVisibility.only(Set.of(ANA));

        assertThat(onlyAna.seesAll()).isFalse();
        assertThat(onlyAna.sees(ANA)).isTrue();
        assertThat(onlyAna.sees(BEA)).isFalse();
        assertThat(PlayerVisibility.only(Set.of()).sees(ANA)).isFalse();
    }

    @Test
    void theVisiblePlayersAreACopy() {
        Set<PlayerId> players = new HashSet<>(Set.of(ANA));
        PlayerVisibility visibility = PlayerVisibility.only(players);
        players.add(BEA);

        assertThat(visibility.sees(BEA)).isFalse();
        assertThatThrownBy(() -> PlayerVisibility.only(null)).isInstanceOf(NullPointerException.class);
    }
}
