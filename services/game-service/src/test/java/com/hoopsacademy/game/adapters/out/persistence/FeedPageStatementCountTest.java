package com.hoopsacademy.game.adapters.out.persistence;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * A feed page costs the same four statements whatever the size of the match and whoever asks (WP60, decision 42 of
 * 2026-11-06): the match lookup ({@code em.find} of an entity without associations plus its projected score), the
 * page and the match's last sequence number. A filtered caller no longer reads the whole match. Statements are counted
 * on the repositories' JDBC funnel ({@code JdbcRepository.query/update/batch}), which the spies record.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@TestSecurity(user = FeedPageStatementCountTest.SUBJECT)
@OidcSecurity(claims = @Claim(key = "sub", value = FeedPageStatementCountTest.SUBJECT))
class FeedPageStatementCountTest {

    static final String SUBJECT = "feed-counter";
    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String TEAM = "11111111-0000-4000-8000-0000000000d1";
    static final String SEASON = "22222222-0000-4000-8000-0000000000d1";
    static final UUID COACH_PERSON = UUID.fromString("33333333-0000-4000-8000-0000000000d1");
    static final PlayerId CHILD = player(1);
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 6)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, n <= 5)).toList();

    @Inject
    MatchSeed seed;

    @InjectSpy
    JpaMatchEventRepository events;

    @InjectSpy
    JpaMatchRepository matches;

    @AfterEach
    void forgetCallers() {
        TenantUserRegistry.clear();
    }

    /** {@code rounds} rounds of six players' shots, each voided through a chain of three VOIDs. */
    private UUID seedMatch(int rounds) {
        UUID match = seed.match(A, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-01T09:00:00Z"), ROSTER);
        Script s = Script.unique().start(1, 600);
        for (int round = 0; round < rounds; round++) {
            for (int n = 1; n <= 6; n++) {
                s.shot(1, 500, player(n), 2, true).voidOf(1, 500, s.last()).voidOf(1, 500, s.last())
                        .voidOf(1, 500, s.last());
            }
        }
        seed.events(A, match, COACH_PERSON, s.events());
        return match;
    }

    private static AuthzContext caller(boolean staff) {
        return staff
                ? new AuthzContext(SUBJECT, UUID.randomUUID(), TenantId.parse(A), Set.of(TenantRole.COACH),
                        Set.of(UUID.fromString(TEAM)), Set.of(), Optional.empty())
                : new AuthzContext(SUBJECT, UUID.randomUUID(), TenantId.parse(A), Set.of(TenantRole.PARENT), Set.of(),
                        Set.of(CHILD.value()), Optional.empty());
    }

    @ParameterizedTest(name = "staff {0}, {1} rounds")
    @CsvSource({"false, 1", "false, 20", "true, 1", "true, 20"})
    void aFeedPageIsFourStatementsWhateverTheMatchSize(boolean staff, int rounds) {
        UUID match = seedMatch(rounds);
        TenantUserRegistry.register(caller(staff));
        clearInvocations(events, matches);

        List<String> ids = given().header("X-Tenant-Id", A)
                .get("/api/game/matches/" + match + "/events?after=0&limit=3")
                .then().statusCode(200).extract().jsonPath().getList("events.event.id", String.class);

        assertThat(ids).hasSize(3);
        verify(matches, times(1)).findById(MatchId.of(match));
        verify(matches, times(1)).query(anyString(), any(), any());
        verify(events, times(1)).after(eq(MatchId.of(match)), any(), anyLong(), anyInt());
        verify(events, times(1)).lastServerSeq(MatchId.of(match));
        verify(events, never()).findByMatch(any());
        verify(events, times(2)).query(anyString(), any(), any());
        verify(events, never()).update(anyString(), any());
        verify(events, never()).batch(anyString(), any());
    }
}
