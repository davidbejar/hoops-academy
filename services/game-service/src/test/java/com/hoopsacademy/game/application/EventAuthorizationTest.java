package com.hoopsacademy.game.application;

import static com.hoopsacademy.game.domain.events.Script.player;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.MatchEvent.FoulKind;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The authz matrix row "Enter player stat events" / "Void events" / "clock & period events" for one event. */
class EventAuthorizationTest {

    static final TenantId TENANT = TenantId.parse("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa");
    static final UUID TEAM = UUID.fromString("11111111-0000-4000-8000-000000000011");
    static final UUID OTHER_TEAM = UUID.fromString("11111111-0000-4000-8000-000000000012");
    static final UUID PARENT_PERSON = UUID.fromString("33333333-0000-4000-8000-000000000001");
    static final UUID COACH_PERSON = UUID.fromString("33333333-0000-4000-8000-000000000002");
    static final PlayerId LINKED = player(1), OTHER = player(2);

    /** Events recorded so far: seq 1 by the coach, seq 2 by the parent. */
    static final Map<EventId, UUID> RECORDERS = Map.of(Script.eventId(1), COACH_PERSON, Script.eventId(2), PARENT_PERSON);

    static AuthzContext caller(UUID person, Set<TenantRole> roles, Set<UUID> staffTeams, Set<UUID> linked, UUID ownPlayer) {
        return new AuthzContext("sub", person, TENANT, roles, staffTeams, linked, Optional.ofNullable(ownPlayer));
    }

    static final AuthzContext ADMIN = caller(UUID.randomUUID(), Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null);
    static final AuthzContext COACH = caller(COACH_PERSON, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
    static final AuthzContext ASSISTANT = caller(UUID.randomUUID(), Set.of(TenantRole.ASSISTANT_COACH), Set.of(TEAM), Set.of(), null);
    static final AuthzContext OTHER_COACH = caller(UUID.randomUUID(), Set.of(TenantRole.COACH), Set.of(OTHER_TEAM), Set.of(), null);
    static final AuthzContext PARENT = caller(PARENT_PERSON, Set.of(TenantRole.PARENT), Set.of(), Set.of(LINKED.value()), null);
    static final AuthzContext PARENT_AND_OTHER_COACH = caller(PARENT_PERSON, Set.of(TenantRole.PARENT, TenantRole.COACH),
            Set.of(OTHER_TEAM), Set.of(LINKED.value()), null);
    static final AuthzContext PLAYER = caller(UUID.randomUUID(), Set.of(TenantRole.PLAYER), Set.of(), Set.of(), LINKED.value());
    static final AuthzContext PLAIN_MEMBER = caller(UUID.randomUUID(), Set.of(), Set.of(), Set.of(), null);

    static Match match() {
        return Match.schedule(MatchId.random(), TeamId.of(TEAM), SeasonId.of(UUID.randomUUID()), "Rivals", HomeAway.HOME,
                Instant.parse("2026-11-01T09:00:00Z"), null, null, null, UUID.randomUUID());
    }

    static Match finishedAt(Instant finishedAt) {
        Match m = match();
        m.start(new MatchRoster(m.id(), List.of(new RosterEntry(LINKED, "Ana", new JerseyNumber("4"), true))),
                Instant.parse("2026-11-01T09:00:00Z"));
        m.finish(finishedAt);
        return m;
    }

    /** Builds one event (its recordedAtClient is Script.BASE + 3 s). */
    static MatchEvent event(java.util.function.Consumer<Script> step) {
        Script script = new Script().start(1, 600).start(1, 600);
        step.accept(script);
        List<RecordedEvent> events = script.events();
        return events.get(events.size() - 1).event();
    }

    static boolean allowed(AuthzContext caller, Match match, MatchEvent event) {
        return EventAuthorization.mayRecord(caller, match, event, id -> Optional.ofNullable(RECORDERS.get(id)));
    }

    @Test
    void adminAndTeamStaffMayRecordAnything() {
        Match m = match();
        for (AuthzContext staff : List.of(ADMIN, COACH, ASSISTANT)) {
            assertThat(allowed(staff, m, event(s -> s.start(1, 600)))).isTrue();
            assertThat(allowed(staff, m, event(s -> s.subIn(1, 500, OTHER)))).isTrue();
            assertThat(allowed(staff, m, event(s -> s.opponent(1, 500, 2)))).isTrue();
            assertThat(allowed(staff, m, event(s -> s.shot(1, 500, OTHER, 2, true)))).isTrue();
            assertThat(allowed(staff, m, event(s -> s.voidOf(1, 500, Script.eventId(2))))).isTrue();
        }
    }

    @Test
    void theTeamsFormerStaffMayStillSyncWhatTheyRecordedSeasonDatesAreCheckedByTheIngest() {
        AuthzContext former = caller(COACH_PERSON, Set.of(TenantRole.COACH), Set.of(OTHER_TEAM), Set.of(), null)
                .withHistoricStaffTeamIds(Set.of(TEAM));

        assertThat(allowed(former, match(), event(s -> s.shot(1, 500, OTHER, 2, true)))).isTrue();
        assertThat(allowed(former, match(), event(s -> s.start(1, 600)))).isTrue();
    }

    @Test
    void staffOfAnotherTeamPlayersAndPlainMembersMayRecordNothing() {
        Match m = match();
        for (AuthzContext outsider : List.of(OTHER_COACH, PLAYER, PLAIN_MEMBER)) {
            assertThat(allowed(outsider, m, event(s -> s.shot(1, 500, LINKED, 2, true)))).isFalse();
            assertThat(allowed(outsider, m, event(s -> s.start(1, 600)))).isFalse();
        }
    }

    @Test
    void parentMayRecordStatEventsOfLinkedPlayersOnly() {
        Match m = match();
        assertThat(allowed(PARENT, m, event(s -> s.shot(1, 500, LINKED, 2, true)))).isTrue();
        assertThat(allowed(PARENT, m, event(s -> s.assist(1, 500, LINKED)))).isTrue();
        assertThat(allowed(PARENT, m, event(s -> s.foul(1, 500, LINKED, FoulKind.PERSONAL)))).isTrue();
        assertThat(allowed(PARENT, m, event(s -> s.shot(1, 500, OTHER, 2, true)))).isFalse();
        assertThat(allowed(PARENT_AND_OTHER_COACH, m, event(s -> s.shot(1, 500, LINKED, 2, true)))).isTrue();
        assertThat(allowed(PARENT_AND_OTHER_COACH, m, event(s -> s.start(1, 600)))).isFalse();
    }

    @Test
    void parentMayNotRecordClockPeriodSubstitutionOpponentTimeoutOrNotes() {
        Match m = match();
        assertThat(allowed(PARENT, m, event(s -> s.start(1, 600)))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.end(1, 0)))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.subIn(1, 500, LINKED)))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.subOut(1, 500, LINKED)))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.opponent(1, 500, 2)))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.timeout(1, 500)))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.note(1, 500, "hi")))).isFalse();
    }

    @Test
    void parentMayVoidOwnEventsOnly() {
        Match m = match();
        assertThat(allowed(PARENT, m, event(s -> s.voidOf(1, 500, Script.eventId(2))))).isTrue();
        assertThat(allowed(PARENT, m, event(s -> s.voidOf(1, 500, Script.eventId(1))))).isFalse();
        assertThat(allowed(PARENT, m, event(s -> s.voidOf(1, 500, Script.eventId(99))))).isFalse();
    }

    @Test
    void aMemberWhoIsNoLongerAParentMayNotVoidWhatTheyRecordedAsOne() {
        AuthzContext formerParent = caller(PARENT_PERSON, Set.of(TenantRole.PLAYER), Set.of(), Set.of(LINKED.value()), null);

        assertThat(allowed(formerParent, match(), event(s -> s.voidOf(1, 500, Script.eventId(2))))).isFalse();
    }

    @Test
    void afterTheFinalWhistleOnlyStaffCorrectionsAndParentEventsRecordedBeforeItCount() {
        MatchEvent shot = event(s -> s.shot(1, 500, LINKED, 2, true)); // recorded at BASE + 3 s
        Match finishedLater = finishedAt(Script.BASE.plusSeconds(60));
        Match finishedEarlier = finishedAt(Script.BASE.plusSeconds(1));

        assertThat(allowed(PARENT, finishedLater, shot)).isTrue();
        assertThat(allowed(PARENT, finishedEarlier, shot)).isFalse();
        assertThat(allowed(COACH, finishedEarlier, shot)).isTrue();
    }
}
