package com.hoopsacademy.game.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MatchRosterTest {

    private static final PlayerId P = PlayerId.of(UUID.randomUUID());

    @Test
    void rejectsDuplicatePlayers() {
        RosterEntry e = new RosterEntry(P, "Ana", null, true);
        assertThatThrownBy(() -> new MatchRoster(MatchId.random(), List.of(e, e)))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("DUPLICATE_PLAYER");
    }

    @Test
    void emptyRosterHasNoStarter() {
        assertThat(MatchRoster.empty(MatchId.random()).hasStarter()).isFalse();
    }

    @Test
    void jerseyNumbersAreOneOrTwoDigits() {
        assertThat(new JerseyNumber("07").value()).isEqualTo("07");
        assertThat(JerseyNumber.ofNullable(null)).isNull();
        assertThatThrownBy(() -> new JerseyNumber("100")).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new JerseyNumber("a")).isInstanceOf(DomainRuleViolation.class);
    }
}
