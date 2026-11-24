package com.hoopsacademy.game.adapters.out.persistence;

import static com.hoopsacademy.game.domain.events.Script.player;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RecordedSpans;
import com.hoopsacademy.common.testing.RequestTrace;
import com.hoopsacademy.common.testing.SampledTrace;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.common.testing.TracingProfile;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.Script;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The SQL of a request shows in its trace (WP143, ADR-0074): with the SDK on, the match event feed yields database
 * spans under the request's server span, and no span carries a seeded player name, a note's text or the tenant id.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@TestProfile(TracingProfile.class)
@TestSecurity(user = DatabaseSpansTest.SUBJECT)
@OidcSecurity(claims = @Claim(key = "sub", value = DatabaseSpansTest.SUBJECT))
class DatabaseSpansTest {

    static final String SUBJECT = "span-reader";
    private static final String TEAM = "11111111-0000-4000-8000-0000000000e1";
    private static final String SEASON = "22222222-0000-4000-8000-0000000000e1";
    private static final String NAME = "Zelphine Quorrowby";
    private static final String NOTE = "Quorrowby twisted an ankle";

    @Inject
    RecordedSpans recorded;

    @Inject
    MatchSeed seed;

    private final String tenant = UUID.randomUUID().toString();
    private UUID match;

    @BeforeEach
    void aLiveMatchWithANote() {
        List<RosterEntry> roster = List.of(new RosterEntry(player(1), NAME, new JerseyNumber("7"), true),
                new RosterEntry(player(2), "Player 2", null, true));
        match = seed.match(tenant, TEAM, SEASON, MatchStatus.LIVE, Instant.parse("2026-11-01T09:00:00Z"), roster);
        Script script = Script.unique().device("bench").start(1, 600).shot(1, 590, player(1), 2, true)
                .note(1, 580, NOTE);
        seed.events(tenant, match, UUID.randomUUID(), script.events());
        TenantUserRegistry.register(new AuthzContext(SUBJECT, UUID.randomUUID(), TenantId.parse(tenant),
                Set.of(TenantRole.ADMIN), Set.of(), Set.of(), Optional.empty()));
    }

    @AfterEach
    void forgetTheCaller() {
        TenantUserRegistry.clear();
    }

    @Test
    void theFeedShowsItsSqlUnderTheRequestSpan() {
        RequestTrace trace = feed();

        assertThat(trace.databaseSpans()).as("database spans of %s", trace.names()).isNotEmpty()
                .allSatisfy(span -> assertThat(trace.isUnderRoot(span)).as(span.getName()).isTrue());
        System.out.printf("WP143 game match event feed: %d spans, %d database spans%n", trace.spans().size(),
                trace.databaseSpans().size());
    }

    @Test
    void noSpanCarriesAValueATenantOrAName() {
        RequestTrace trace = feed();

        assertThat(trace.databaseSpans()).as("the check needs database spans").isNotEmpty();
        assertThat(trace.exportedText()).doesNotContain("Zelphine", "Quorrowby", tenant);
    }

    private RequestTrace feed() {
        SampledTrace trace = SampledTrace.random();
        given().filter(Contract.FILTER).header("X-Tenant-Id", tenant).header("traceparent", trace.traceparent())
                .get("/api/game/matches/" + match + "/events").then().statusCode(200);
        return recorded.of(trace);
    }
}
