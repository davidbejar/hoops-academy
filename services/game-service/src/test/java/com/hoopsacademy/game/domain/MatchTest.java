package com.hoopsacademy.game.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.CodedProblemException;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MatchTest {

    private static final Instant NOW = Instant.parse("2026-11-01T10:00:00Z");
    private static final Instant LATER = NOW.plusSeconds(3600);
    private static final MatchRoster WITH_STARTER = new MatchRoster(MatchId.random(),
            List.of(new RosterEntry(PlayerId.of(UUID.randomUUID()), "Ana", new JerseyNumber("7"), true)));
    private static final MatchRoster NO_STARTER = new MatchRoster(MatchId.random(),
            List.of(new RosterEntry(PlayerId.of(UUID.randomUUID()), "Bo", null, false)));

    private static Match scheduled() {
        return Match.schedule(MatchId.random(), TeamId.of(UUID.randomUUID()), SeasonId.of(UUID.randomUUID()), "Rivals",
                HomeAway.HOME, LATER, "Gym", null, null, UUID.randomUUID());
    }

    private static Match live() {
        Match m = scheduled();
        m.start(WITH_STARTER, NOW);
        return m;
    }

    @Test
    void newMatchIsScheduledWithDefaultPeriods() {
        Match m = scheduled();
        assertThat(m.status()).isEqualTo(MatchStatus.SCHEDULED);
        assertThat(m.periodCount()).isEqualTo(4);
        assertThat(m.periodMinutes()).isEqualTo(10);
        assertThat(m.version()).isZero();
    }

    @Test
    void startMovesToLiveAndRecordsTime() {
        Match m = scheduled();
        m.start(WITH_STARTER, NOW);
        assertThat(m.status()).isEqualTo(MatchStatus.LIVE);
        assertThat(m.startedAt()).isEqualTo(NOW);
    }

    @Test
    void startNeedsAStarter() {
        assertThatThrownBy(() -> scheduled().start(NO_STARTER, NOW))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("NO_STARTERS");
    }

    @Test
    void startingALiveMatchIsIdempotent() {
        Match m = live();
        m.start(NO_STARTER, LATER);
        assertThat(m.status()).isEqualTo(MatchStatus.LIVE);
        assertThat(m.startedAt()).isEqualTo(NOW);
    }

    @Test
    void finishMovesLiveToFinished() {
        Match m = live();
        m.finish(LATER);
        assertThat(m.status()).isEqualTo(MatchStatus.FINISHED);
        assertThat(m.finishedAt()).isEqualTo(LATER);
    }

    @Test
    void cannotFinishAScheduledMatch() {
        assertThatThrownBy(() -> scheduled().finish(NOW)).isInstanceOf(ConflictException.class);
    }

    @Test
    void cannotStartFinishedOrCancelledMatches() {
        Match finished = live();
        finished.finish(LATER);
        Match cancelled = scheduled();
        cancelled.cancel("rain", NOW);
        assertThatThrownBy(() -> finished.start(WITH_STARTER, NOW)).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> cancelled.start(WITH_STARTER, NOW)).isInstanceOf(ConflictException.class);
    }

    @Test
    void cancelFromScheduledAndLive() {
        Match a = scheduled();
        a.cancel("rain", NOW);
        Match b = live();
        b.cancel("injury", LATER);
        assertThat(a.status()).isEqualTo(MatchStatus.CANCELLED);
        assertThat(a.cancelReason()).isEqualTo("rain");
        assertThat(a.cancelledAt()).isEqualTo(NOW);
        assertThat(b.status()).isEqualTo(MatchStatus.CANCELLED);
    }

    @Test
    void cannotCancelFinishedOrCancelled() {
        Match finished = live();
        finished.finish(LATER);
        Match cancelled = scheduled();
        cancelled.cancel("rain", NOW);
        assertThatThrownBy(() -> finished.cancel("x", NOW)).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> cancelled.cancel("x", NOW)).isInstanceOf(ConflictException.class);
    }

    @Test
    void cancelNeedsAReason() {
        assertThatThrownBy(() -> scheduled().cancel(" ", NOW)).isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void invalidTransitionsCarryTheInvalidStateCode() {
        assertThatThrownBy(() -> scheduled().finish(NOW)).isInstanceOf(CodedProblemException.class)
                .extracting("code").isEqualTo("INVALID_STATE");
    }

    @Test
    void updateChangesGivenFieldsOnly() {
        Match m = scheduled();
        m.update("New", HomeAway.AWAY, NOW, true, null, 2, 12);
        assertThat(m.opponentName()).isEqualTo("New");
        assertThat(m.homeAway()).isEqualTo(HomeAway.AWAY);
        assertThat(m.scheduledAt()).isEqualTo(NOW);
        assertThat(m.venue()).isNull();
        assertThat(m.periodCount()).isEqualTo(2);
        assertThat(m.periodMinutes()).isEqualTo(12);
        m.update(null, null, null, false, null, null, null);
        assertThat(m.opponentName()).isEqualTo("New");
    }

    @Test
    void periodSettingsAreFrozenOnceLive() {
        Match m = live();
        assertThatThrownBy(() -> m.update(null, null, null, false, null, 2, null)).isInstanceOf(ConflictException.class);
        m.update("Other", null, null, false, null, null, null);
        assertThat(m.opponentName()).isEqualTo("Other");
    }

    @Test
    void finishedMatchCannotBeEdited() {
        Match m = live();
        m.finish(LATER);
        assertThatThrownBy(() -> m.update("x", null, null, false, null, null, null)).isInstanceOf(ConflictException.class);
        assertThatThrownBy(m::requireRosterEditable).isInstanceOf(ConflictException.class);
    }

    @Test
    void rejectsOutOfRangeValues() {
        assertThatThrownBy(() -> Match.schedule(MatchId.random(), TeamId.of(UUID.randomUUID()), SeasonId.of(UUID.randomUUID()),
                "X", HomeAway.HOME, NOW, null, 9, null, UUID.randomUUID())).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> scheduled().update(null, null, null, false, null, null, 61)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> scheduled().update(" ", null, null, false, null, null, null)).isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void restoreKeepsAllFields() {
        Match m = Match.restore(MatchId.random(), TeamId.of(UUID.randomUUID()), SeasonId.of(UUID.randomUUID()), "O",
                HomeAway.AWAY, NOW, "V", MatchStatus.FINISHED, 3, 8, NOW, LATER, null, null, UUID.randomUUID(), 5);
        assertThat(m.status()).isEqualTo(MatchStatus.FINISHED);
        assertThat(m.version()).isEqualTo(5);
        assertThat(m.finishedAt()).isEqualTo(LATER);
    }
}
