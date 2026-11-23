package com.hoopsacademy.game.adapters.out.persistence;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.doAnswer;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.RecordedEvent;
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
import io.restassured.path.json.JsonPath;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.IntStream;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/**
 * The feed's {@code lastServerSeq} is the cursor for the next call when {@code hasMore} is false (contract
 * listMatchEvents). It must never pass an event the page did not hold: a batch another device commits while the page is
 * read (READ COMMITTED) is returned by the next call, not skipped (WP126, GAME-04).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@TestSecurity(user = FeedCursorTest.SUBJECT)
@OidcSecurity(claims = @Claim(key = "sub", value = FeedCursorTest.SUBJECT))
class FeedCursorTest {

    static final String SUBJECT = "feed-cursor";
    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String TEAM = "11111111-0000-4000-8000-0000000000d2";
    static final String SEASON = "22222222-0000-4000-8000-0000000000d2";
    static final UUID COACH_PERSON = UUID.fromString("33333333-0000-4000-8000-0000000000d2");
    static final List<RosterEntry> ROSTER = IntStream.rangeClosed(1, 5)
            .mapToObj(n -> new RosterEntry(player(n), "Player " + n, null, true)).toList();

    @Inject
    MatchSeed seed;

    @InjectSpy
    JpaMatchEventRepository events;

    @AfterEach
    void forgetCallers() {
        TenantUserRegistry.clear();
    }

    @Test
    void aBatchCommittedWhileThePageIsReadComesWithTheNextCall() {
        UUID match = seed.match(A, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-02T09:00:00Z"), ROSTER);
        List<RecordedEvent> script = Script.unique().start(1, 600).shot(1, 590, player(1), 2, true).events();
        seed.events(A, match, COACH_PERSON, script.subList(0, 1));
        RecordedEvent late = script.get(1);
        TenantUserRegistry.register(new AuthzContext(SUBJECT, UUID.randomUUID(), TenantId.parse(A),
                Set.of(TenantRole.COACH), Set.of(UUID.fromString(TEAM)), Set.of(), Optional.empty()));
        AtomicBoolean once = new AtomicBoolean();
        doAnswer(call -> {
            Object page = call.callRealMethod();
            if (once.compareAndSet(false, true)) {
                CompletableFuture.runAsync(() -> seed.events(A, match, COACH_PERSON, List.of(late))).join();
            }
            return page;
        }).when(events).after(any(), any(), anyLong(), anyInt());

        JsonPath first = feed(match, 0);
        assertThat(first.getList("events.event.id", String.class)).containsExactly(script.get(0).id().toString());
        assertThat(first.getBoolean("hasMore")).isFalse();

        JsonPath next = feed(match, first.getLong("lastServerSeq"));
        assertThat(next.getList("events.event.id", String.class)).as("the event committed in between")
                .containsExactly(late.id().toString());
    }

    private static JsonPath feed(UUID match, long after) {
        return given().header("X-Tenant-Id", A)
                .get("/api/game/matches/" + match + "/events?after=" + after + "&limit=50")
                .then().statusCode(200).extract().jsonPath();
    }
}
