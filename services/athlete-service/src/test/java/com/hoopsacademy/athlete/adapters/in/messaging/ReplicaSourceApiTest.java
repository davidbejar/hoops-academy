package com.hoopsacademy.athlete.adapters.in.messaging;

import static io.restassured.RestAssured.given;

import com.hoopsacademy.athlete.application.replica.ReplicaAuthzResolver;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.CoreTopics;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * hoops.roster.source=replica end to end through the API without any core-service: the tenant filter resolves the
 * caller from the replica (non-members and suspended tenants are 404) and the use cases' RosterPort reads the replica
 * (creating a schedule checks the team's roster).
 */
@QuarkusTest
@TestProfile(ReplicaProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@TestSecurity(user = "replica-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "replica-user"))
class ReplicaSourceApiTest {

    static final String URL = "/api/athlete/training-schedules";
    static final Duration TIMEOUT = Duration.ofSeconds(30);

    @Inject ReplicaAuthzResolver resolver;
    @Inject TenantScope tenantScope;

    CoreTopics topics;
    TenantId tenant;
    UUID team;

    @BeforeEach
    void setUp() {
        topics = new CoreTopics();
        tenant = TenantId.random();
        team = UUID.randomUUID();
    }

    @AfterEach
    void close() {
        topics.close();
    }

    @Test
    void aCoachFromTheReplicaCreatesAScheduleForTheirTeam() {
        UUID person = UUID.randomUUID();
        topics.publish(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"),
                CoreEvents.team(tenant, team, "U12", LocalDate.now().plusMonths(6)),
                CoreEvents.person(tenant, person, "Cole Coach", "replica-user", List.of("COACH"), true),
                CoreEvents.teamStaff(tenant, team, person, "COACH"));
        awaitMember(true);

        given().header("X-Tenant-Id", tenant.toString()).get(URL).then().statusCode(200);
        given().header("X-Tenant-Id", tenant.toString()).contentType("application/json")
                .body("{\"teamId\":\"%s\",\"dayOfWeek\":\"MONDAY\",\"startTime\":\"18:00\",\"durationMinutes\":60,\"validFrom\":\"2030-01-01\"}"
                        .formatted(team))
                .post(URL).then().statusCode(201);
    }

    @Test
    void aLoginWithoutAPersonInTheTenantIs404() {
        topics.publish(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"),
                CoreEvents.person(tenant, UUID.randomUUID(), "Some One", "someone-else", List.of("ADMIN"), true));
        CoreTopics.await("the tenant", TIMEOUT,
                () -> tenantScope.runAs(tenant, () -> resolver.resolve("someone-else", tenant)).isPresent());

        given().header("X-Tenant-Id", tenant.toString()).get(URL).then().statusCode(404);
    }

    @Test
    void aMemberOfASuspendedTenantIs404() {
        UUID person = UUID.randomUUID();
        topics.publish(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"),
                CoreEvents.person(tenant, person, "Ada Admin", "replica-user", List.of("ADMIN"), true));
        awaitMember(true);

        topics.publish(CoreEvents.tenant(tenant, "SUSPENDED", "Europe/Madrid"));
        awaitMember(false);

        given().header("X-Tenant-Id", tenant.toString()).get(URL).then().statusCode(404);
    }

    private void awaitMember(boolean member) {
        CoreTopics.await("membership = " + member, TIMEOUT,
                () -> tenantScope.runAs(tenant, () -> resolver.resolve("replica-user", tenant)).isPresent() == member);
    }
}
