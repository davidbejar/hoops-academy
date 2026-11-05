package com.hoopsacademy.game.adapters.in.rest;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.MatchEvent.FoulKind;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.EventSchema;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import io.restassured.path.json.JsonPath;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * docs/domain/authz-matrix.md "Read the match event feed" (security review F-01, ADR-0030): ADMIN and staff of the
 * match's team read every event; everybody else reads the team-level events plus the events of their own or linked
 * players. A VOID is visible when the event it voids is.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@TestSecurity(user = MatchEventFeedRoleMatrixTest.SUBJECT)
@OidcSecurity(claims = @Claim(key = "sub", value = MatchEventFeedRoleMatrixTest.SUBJECT))
class MatchEventFeedRoleMatrixTest {

    static final String SUBJECT = "feed-viewer";
    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    static final String TEAM = "11111111-0000-4000-8000-0000000000f1";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-0000000000f2";
    static final String SEASON = "22222222-0000-4000-8000-0000000000f1";
    static final UUID COACH_PERSON = UUID.fromString("33333333-0000-4000-8000-0000000000f1");
    static final PlayerId CHILD = player(1), TEAMMATE = player(2), SUB = player(6), STRANGER = player(9);
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 6)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5)).toList();

    /** Team-level events (visible to every member) and the events of CHILD, in posting order. */
    enum Sees { EVERYTHING, TEAM_AND_CHILD, TEAM_ONLY }

    /** A caller: roles and relations, named for the test report. */
    record Caller(String name, Set<TenantRole> roles, Set<UUID> staffTeams, Set<UUID> linked, PlayerId own) {

        AuthzContext in(String tenant) {
            return new AuthzContext(SUBJECT, UUID.nameUUIDFromBytes(name.getBytes()), TenantId.parse(tenant), roles,
                    staffTeams, linked, Optional.ofNullable(own).map(PlayerId::value));
        }

        @Override
        public String toString() {
            return name;
        }
    }

    static Stream<Arguments> callers() {
        UUID team = UUID.fromString(TEAM), otherTeam = UUID.fromString(OTHER_TEAM);
        return Stream.of(
                Arguments.of(new Caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null), Sees.EVERYTHING),
                Arguments.of(new Caller("COACH of the team", Set.of(TenantRole.COACH), Set.of(team), Set.of(), null),
                        Sees.EVERYTHING),
                Arguments.of(new Caller("ASSISTANT_COACH of the team", Set.of(TenantRole.ASSISTANT_COACH), Set.of(team),
                        Set.of(), null), Sees.EVERYTHING),
                Arguments.of(new Caller("ADMIN+PLAYER", Set.of(TenantRole.ADMIN, TenantRole.PLAYER), Set.of(), Set.of(),
                        STRANGER), Sees.EVERYTHING),
                Arguments.of(new Caller("PARENT linked to the child", Set.of(TenantRole.PARENT), Set.of(),
                        Set.of(CHILD.value()), null), Sees.TEAM_AND_CHILD),
                Arguments.of(new Caller("PLAYER (the child)", Set.of(TenantRole.PLAYER), Set.of(), Set.of(), CHILD),
                        Sees.TEAM_AND_CHILD),
                Arguments.of(new Caller("COACH of another team + PARENT linked", Set.of(TenantRole.COACH, TenantRole.PARENT),
                        Set.of(otherTeam), Set.of(CHILD.value()), null), Sees.TEAM_AND_CHILD),
                Arguments.of(new Caller("PARENT without a link to this match", Set.of(TenantRole.PARENT), Set.of(),
                        Set.of(STRANGER.value()), null), Sees.TEAM_ONLY),
                Arguments.of(new Caller("PARENT with no link at all", Set.of(TenantRole.PARENT), Set.of(), Set.of(), null),
                        Sees.TEAM_ONLY),
                Arguments.of(new Caller("PLAYER not in the match", Set.of(TenantRole.PLAYER), Set.of(), Set.of(), STRANGER),
                        Sees.TEAM_ONLY),
                Arguments.of(new Caller("COACH of another team", Set.of(TenantRole.COACH), Set.of(otherTeam), Set.of(), null),
                        Sees.TEAM_ONLY),
                Arguments.of(new Caller("member without role", Set.of(), Set.of(), Set.of(), null), Sees.TEAM_ONLY));
    }

    @Inject
    MatchSeed seed;

    @AfterEach
    void forgetCallers() {
        TenantUserRegistry.clear();
    }

    /** A seeded match: every event type, a VOID of the child's shot and one of a teammate's shot. */
    record Seeded(UUID match, List<String> everything, List<String> teamAndChild, List<String> teamOnly) {

        List<String> expected(Sees sees) {
            return switch (sees) {
                case EVERYTHING -> everything;
                case TEAM_AND_CHILD -> teamAndChild;
                case TEAM_ONLY -> teamOnly;
            };
        }
    }

    Seeded seedMatch() {
        UUID match = seed.match(A, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-01T09:00:00Z"), ROSTER);
        Script s = Script.unique().device("bench")
                .start(1, 600)                                 // 1 team
                .shot(1, 590, CHILD, 2, true)                  // 2 child
                .shot(1, 580, TEAMMATE, 3, true)               // 3 teammate
                .assist(1, 580, TEAMMATE)                      // 4 teammate
                .subOut(1, 570, TEAMMATE)                      // 5 teammate
                .subIn(1, 570, SUB)                            // 6 substitute
                .opponent(1, 560, 2)                           // 7 team
                .timeout(1, 550)                               // 8 team
                .note(1, 540, "Referee change")                // 9 team
                .foul(1, 530, CHILD, FoulKind.PERSONAL);       // 10 child
        List<RecordedEvent> first = s.events();
        s.voidOf(1, 520, first.get(2).id())                    // 11 VOID of the teammate's shot
                .voidOf(1, 510, first.get(1).id())             // 12 VOID of the child's shot
                .end(1, 0);                                    // 13 team
        seed.events(A, match, COACH_PERSON, s.events());
        List<String> ids = s.events().stream().map(e -> e.id().toString()).toList();
        return new Seeded(match, ids,
                pick(ids, 1, 2, 7, 8, 9, 10, 12, 13),
                pick(ids, 1, 7, 8, 9, 13));
    }

    private static List<String> pick(List<String> ids, int... positions) {
        return IntStream.of(positions).mapToObj(p -> ids.get(p - 1)).toList();
    }

    private static JsonPath feed(String tenant, UUID match, String query, int status) {
        var response = given().filter(Contract.FILTER).header("X-Tenant-Id", tenant)
                .get("/api/game/matches/" + match + "/events" + query).then().statusCode(status);
        String body = response.extract().asString();
        if (status == 200) {
            EventSchema.assertValidFeed(body);
        }
        return JsonPath.from(body);
    }

    @ParameterizedTest(name = "{0} reads {1}")
    @MethodSource("callers")
    void theFeedHoldsTheEventsTheCallerMayRead(Caller caller, Sees sees) {
        Seeded seeded = seedMatch();
        TenantUserRegistry.register(caller.in(A));

        JsonPath page = feed(A, seeded.match(), "", 200);

        assertThat(page.getList("events.event.id", String.class)).containsExactlyElementsOf(seeded.expected(sees));
        assertThat(page.getBoolean("hasMore")).isFalse();
        assertThat(page.getList("events.serverSeq", Long.class)).isSorted();
    }

    @ParameterizedTest(name = "{0} pages through {1}")
    @MethodSource("callers")
    void pagingWalksTheCallersEventsOnly(Caller caller, Sees sees) {
        Seeded seeded = seedMatch();
        TenantUserRegistry.register(caller.in(A));

        List<String> walked = new ArrayList<>();
        long after = 0;
        boolean hasMore = true;
        while (hasMore) {
            JsonPath page = feed(A, seeded.match(), "?after=" + after + "&limit=2", 200);
            List<Long> seqs = page.getList("events.serverSeq", Long.class);
            assertThat(seqs).hasSizeLessThanOrEqualTo(2);
            walked.addAll(page.getList("events.event.id", String.class));
            hasMore = page.getBoolean("hasMore");
            if (hasMore) {
                assertThat(seqs).as("a page before the last one is full").hasSize(2);
            }
            after = seqs.isEmpty() ? after : seqs.get(seqs.size() - 1);
        }

        assertThat(walked).containsExactlyElementsOf(seeded.expected(sees));
    }

    @Test
    void theCursorOfTheLastPageIsTheMatchsLastServerSeqForEveryCaller() {
        Seeded seeded = seedMatch();
        TenantUserRegistry.register(new Caller("ADMIN", Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null).in(A));
        long last = feed(A, seeded.match(), "", 200).getLong("lastServerSeq");
        TenantUserRegistry.clear();
        TenantUserRegistry.register(new Caller("PARENT", Set.of(TenantRole.PARENT), Set.of(), Set.of(), null).in(A));

        JsonPath parent = feed(A, seeded.match(), "", 200);

        assertThat(parent.getLong("lastServerSeq")).isEqualTo(last);
        assertThat(feed(A, seeded.match(), "?after=" + last, 200).getList("events")).isEmpty();
    }

    @Test
    void anotherTenantsMatchStaysNotFoundForAFilteredCaller() {
        UUID inB = seed.match(B, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-01T09:00:00Z"), ROSTER);
        Caller parent = new Caller("PARENT linked", Set.of(TenantRole.PARENT), Set.of(), Set.of(CHILD.value()), null);
        TenantUserRegistry.register(parent.in(A));

        feed(A, inB, "", 404);
        given().header("X-Tenant-Id", B).get("/api/game/matches/" + inB + "/events").then().statusCode(404);
    }
}
