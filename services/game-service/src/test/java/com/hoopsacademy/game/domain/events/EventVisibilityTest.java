package com.hoopsacademy.game.domain.events;

import static com.hoopsacademy.game.domain.events.Script.player;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import com.hoopsacademy.game.domain.events.MatchEvent.FoulKind;
import com.hoopsacademy.game.domain.events.MatchEvent.ReboundKind;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** ADR-0030: which events of a match a viewer whose player visibility is restricted may read. */
class EventVisibilityTest {

    static final PlayerId OWN = player(1), OTHER = player(2);
    static final PlayerVisibility ONLY_OWN = PlayerVisibility.only(Set.of(OWN));

    static List<MatchEvent> events(Script script) {
        return script.events().stream().map(RecordedEvent::event).toList();
    }

    static List<MatchEventType> visibleTypes(List<MatchEvent> match, PlayerVisibility viewer) {
        EventVisibility visibility = EventVisibility.of(match, viewer);
        return match.stream().filter(visibility::visible).map(MatchEvent::type).toList();
    }

    @Test
    void teamLevelEventsAreVisibleToEveryViewer() {
        List<MatchEvent> match = events(new Script().start(1, 600).opponent(1, 500, 2).timeout(1, 400)
                .note(1, 300, "Gym is cold").end(1, 0));

        assertThat(visibleTypes(match, ONLY_OWN)).containsExactly(MatchEventType.PERIOD_START,
                MatchEventType.OPPONENT_SCORE, MatchEventType.TIMEOUT, MatchEventType.NOTE, MatchEventType.PERIOD_END);
        assertThat(visibleTypes(match, PlayerVisibility.only(Set.of()))).hasSize(5);
    }

    @Test
    void playerEventsAreVisibleOnlyForVisiblePlayers() {
        Script script = new Script();
        for (PlayerId p : List.of(OWN, OTHER)) {
            script.subIn(1, 590, p).shot(1, 580, p, 2, true).assist(1, 570, p).rebound(1, 560, p, ReboundKind.DEFENSIVE)
                    .turnover(1, 550, p).steal(1, 540, p).block(1, 530, p).foul(1, 520, p, FoulKind.PERSONAL)
                    .subOut(1, 510, p);
        }
        List<MatchEvent> match = events(script);
        EventVisibility visibility = EventVisibility.of(match, ONLY_OWN);

        assertThat(match.stream().filter(visibility::visible))
                .hasSize(9)
                .allSatisfy(e -> assertThat(e.playerId()).contains(OWN));
    }

    @Test
    void aNoteAboutAPlayerIsAPlayerEvent() {
        MatchEvent aboutOwn = note(1, OWN);
        MatchEvent aboutOther = note(2, OTHER);
        EventVisibility visibility = EventVisibility.of(List.of(aboutOwn, aboutOther), ONLY_OWN);

        assertThat(visibility.visible(aboutOwn)).isTrue();
        assertThat(visibility.visible(aboutOther)).isFalse();
    }

    @Test
    void aVoidIsVisibleExactlyWhenItsTargetIs() {
        Script script = new Script().shot(1, 500, OWN, 2, true).shot(1, 490, OTHER, 3, true).opponent(1, 480, 2);
        List<RecordedEvent> stored = script.events();
        script.voidOf(1, 470, stored.get(0).id()).voidOf(1, 460, stored.get(1).id()).voidOf(1, 450, stored.get(2).id());
        List<MatchEvent> match = events(script);
        EventVisibility visibility = EventVisibility.of(match, ONLY_OWN);

        assertThat(match.stream().map(visibility::visible))
                .containsExactly(true, false, true, true, false, true);
    }

    @Test
    void aVoidOfAVoidFollowsTheChainToTheOriginalEvent() {
        Script script = new Script().shot(1, 500, OTHER, 2, true).shot(1, 490, OWN, 2, true);
        script.voidOf(1, 480, Script.eventId(1)).voidOf(1, 470, Script.eventId(3))
                .voidOf(1, 460, Script.eventId(2)).voidOf(1, 450, Script.eventId(5));
        List<MatchEvent> match = events(script);
        EventVisibility visibility = EventVisibility.of(match, ONLY_OWN);

        assertThat(match.stream().map(visibility::visible)).containsExactly(false, true, false, false, true, true);
    }

    @Test
    void aVoidOfAnUnknownEventIsVisibleBecauseItRevealsNoPlayer() {
        List<MatchEvent> match = events(new Script().voidOf(1, 500, EventId.of(UUID.randomUUID())));

        assertThat(EventVisibility.of(match, ONLY_OWN).visible(match.get(0))).isTrue();
    }

    @Test
    void aCycleOfVoidsTerminatesAndRevealsNoPlayer() {
        EventId first = Script.eventId(1), second = Script.eventId(2);
        MatchEvent a = new MatchEvent.Void(meta(first), second);
        MatchEvent b = new MatchEvent.Void(meta(second), first);
        MatchEvent self = new MatchEvent.Void(meta(Script.eventId(3)), Script.eventId(3));
        EventVisibility visibility = EventVisibility.of(List.of(a, b, self), ONLY_OWN);

        assertThat(visibility.visible(a)).isTrue();
        assertThat(visibility.visible(b)).isTrue();
        assertThat(visibility.visible(self)).isTrue();
    }

    @Test
    void aViewerWhoSeesEveryPlayerSeesEveryEvent() {
        Script script = new Script().start(1, 600).shot(1, 500, OTHER, 2, true).subOut(1, 400, OTHER);
        script.voidOf(1, 300, Script.eventId(2));
        List<MatchEvent> match = events(script);

        assertThat(visibleTypes(match, PlayerVisibility.everyone())).hasSize(4);
    }

    private static MatchEvent note(long seq, PlayerId about) {
        return new MatchEvent.Note(meta(Script.eventId(seq)), about, "Great defence");
    }

    private static EventMeta meta(EventId id) {
        return new EventMeta(id, "bench", id.value().getLeastSignificantBits(), 1, 500, Instant.parse("2026-11-01T10:00:00Z"));
    }
}
