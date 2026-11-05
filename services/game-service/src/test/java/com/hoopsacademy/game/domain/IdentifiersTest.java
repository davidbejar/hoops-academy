package com.hoopsacademy.game.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class IdentifiersTest {

    private static final UUID ID = UUID.fromString("11111111-2222-4333-8444-555555555555");

    @Test
    void identifiersPrintAsTheirUuid() {
        assertThat(MatchId.of(ID).value()).isEqualTo(ID);
        assertThat(MatchId.of(ID)).hasToString(ID.toString());
        assertThat(SeasonId.of(ID)).hasToString(ID.toString());
        assertThat(TeamId.of(ID)).hasToString(ID.toString());
    }

    @Test
    void jerseyNumbersAreOneOrTwoDigitsAndOptional() {
        assertThat(JerseyNumber.ofNullable(null)).isNull();
        assertThat(JerseyNumber.ofNullable("07")).isEqualTo(new JerseyNumber("07"));
        assertThatThrownBy(() -> new JerseyNumber(null)).hasMessageContaining("one or two digits");
        assertThatThrownBy(() -> JerseyNumber.ofNullable("123")).hasMessageContaining("one or two digits");
    }
}
