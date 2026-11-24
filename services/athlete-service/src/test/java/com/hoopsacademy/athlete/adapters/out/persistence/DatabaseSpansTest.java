package com.hoopsacademy.athlete.adapters.out.persistence;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RecordedSpans;
import com.hoopsacademy.common.testing.RequestTrace;
import com.hoopsacademy.common.testing.SampledTrace;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.testing.TracingProfile;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import jakarta.inject.Inject;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The SQL of a request shows in its trace (WP143, ADR-0074): with the SDK on, a training session's attendance sheet
 * yields database spans under the request's server span, and no span carries an attendance note (written as a bound
 * value) or the tenant id.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestProfile(TracingProfile.class)
class DatabaseSpansTest {

    static final String TENANT = "54300000-0000-4000-8000-000000000001";
    static final String TEAM = "54300000-0000-4000-8000-0000000000a1";
    static final String P1 = "54300000-0000-4000-8000-0000000000b1";
    static final String P2 = "54300000-0000-4000-8000-0000000000b2";
    private static final String NOTE = "Zelphine Quorrowby missed the bus";

    @Inject
    RecordedSpans recorded;

    private String session;

    @BeforeEach
    void aSessionOfATeamOfTwo() {
        new CoreStubs().reset().roster(TENANT, TEAM, P1, P2).knownPlayers(TENANT, P1, P2);
        member(TENANT, Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null);
        session = api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-03-02T17:00:00Z", "durationMinutes", 90))
                .post("/api/athlete/training-sessions").then().statusCode(201).extract().path("id");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void theSessionSheetShowsItsSqlUnderTheRequestSpan() {
        RequestTrace trace = sheet();

        assertThat(trace.databaseSpans()).as("database spans of %s", trace.names()).isNotEmpty()
                .allSatisfy(span -> assertThat(trace.isUnderRoot(span)).as(span.getName()).isTrue());
        System.out.printf("WP143 athlete session sheet: %d spans, %d database spans%n", trace.spans().size(),
                trace.databaseSpans().size());
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void noSpanCarriesAValueATenantOrAName() {
        SampledTrace write = SampledTrace.random();
        api(TENANT).header("traceparent", write.traceparent())
                .body(Map.of("entries", List.of(Map.of("playerId", P1, "status", "ABSENT", "note", NOTE))))
                .put("/api/athlete/training-sessions/" + session + "/attendance").then().statusCode(200);
        RequestTrace written = recorded.of(write);
        RequestTrace read = sheet();

        assertThat(written.databaseSpans()).as("the check needs database spans").isNotEmpty();
        assertThat(written.exportedText() + "\n" + read.exportedText())
                .doesNotContain("Zelphine", "Quorrowby", TENANT);
    }

    private RequestTrace sheet() {
        SampledTrace trace = SampledTrace.random();
        api(TENANT).header("traceparent", trace.traceparent())
                .get("/api/athlete/training-sessions/" + session + "/attendance").then().statusCode(200);
        return recorded.of(trace);
    }
}
