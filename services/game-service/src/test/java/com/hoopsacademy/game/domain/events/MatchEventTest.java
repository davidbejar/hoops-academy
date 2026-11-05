package com.hoopsacademy.game.domain.events;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import com.hoopsacademy.game.domain.PlayerId;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MatchEventTest {

    private static final EventMeta META = new EventMeta(EventId.of(UUID.randomUUID()), "tablet-1", 1, 1, 600,
            Instant.parse("2026-11-01T10:00:00Z"));
    private static final PlayerId PLAYER = Script.player(1);

    @Test
    void everyEventNamesItsContractType() {
        List<MatchEvent> events = List.of(new MatchEvent.PeriodStart(META), new MatchEvent.PeriodEnd(META),
                new MatchEvent.SubIn(META, PLAYER), new MatchEvent.SubOut(META, PLAYER),
                new MatchEvent.Shot(META, PLAYER, 2, true), new MatchEvent.Assist(META, PLAYER),
                new MatchEvent.Rebound(META, PLAYER, MatchEvent.ReboundKind.DEFENSIVE), new MatchEvent.Turnover(META, PLAYER),
                new MatchEvent.Steal(META, PLAYER), new MatchEvent.Block(META, PLAYER),
                new MatchEvent.Foul(META, PLAYER, MatchEvent.FoulKind.PERSONAL), new MatchEvent.OpponentScore(META, 2),
                new MatchEvent.Timeout(META, MatchEvent.TimeoutSide.OWN), new MatchEvent.Void(META, META.id()),
                new MatchEvent.Note(META, null, "hi"));

        assertThat(events).extracting(MatchEvent::type).containsExactly(MatchEventType.values());
    }

    @Test
    void shotsAndOpponentScoresAreWorthOneToThreePoints() {
        assertThat(new MatchEvent.Shot(META, PLAYER, 1, true).points()).isEqualTo(1);
        assertThat(new MatchEvent.Shot(META, PLAYER, 3, true).points()).isEqualTo(3);
        assertThat(new MatchEvent.OpponentScore(META, 1).points()).isEqualTo(1);
        assertThat(new MatchEvent.OpponentScore(META, 3).points()).isEqualTo(3);
        for (int invalid : new int[] {0, 4}) {
            assertThatIllegalArgumentException().isThrownBy(() -> new MatchEvent.Shot(META, PLAYER, invalid, true));
            assertThatIllegalArgumentException().isThrownBy(() -> new MatchEvent.OpponentScore(META, invalid));
        }
    }
}
