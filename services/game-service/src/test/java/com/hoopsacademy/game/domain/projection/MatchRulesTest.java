package com.hoopsacademy.game.domain.projection;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MatchRulesTest {

    @Test
    void everyCountAndLengthMustBeAtLeastOne() {
        assertThat(new MatchRules(1, 1, 1).periodSeconds(1)).isEqualTo(60);
        assertThatIllegalArgumentException().isThrownBy(() -> new MatchRules(0, 10, 5));
        assertThatIllegalArgumentException().isThrownBy(() -> new MatchRules(4, 0, 5));
        assertThatIllegalArgumentException().isThrownBy(() -> new MatchRules(4, 10, 0));
    }

    @Test
    void theLastRegularPeriodHasTheRegularLengthAndLaterOnesAreOvertimes() {
        MatchRules rules = new MatchRules(4, 10, 5);

        assertThat(rules.periodSeconds(4)).isEqualTo(600);
        assertThat(rules.periodSeconds(5)).isEqualTo(300);
    }

    @Test
    void takesThePeriodSettingsOfTheMatch() {
        Match match = Match.schedule(MatchId.random(), TeamId.of(UUID.randomUUID()), SeasonId.of(UUID.randomUUID()), "R",
                HomeAway.HOME, Instant.parse("2026-11-01T10:00:00Z"), null, 2, 12, UUID.randomUUID());

        assertThat(MatchRules.of(match, 3)).isEqualTo(new MatchRules(2, 12, 3));
    }
}
