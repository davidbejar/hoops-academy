package com.hoopsacademy.core.adapters.in.scheduler;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.SaslRedpandaResource;
import com.hoopsacademy.core.testsupport.TopicReader;
import com.hoopsacademy.core.testsupport.TopicReader.Event;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * WP81 (the failure WP71 found on kind): core starts before its broker user exists, so the producer's very first login
 * fails. Once the user is created, publishing resumes by itself, without restarting core: the publisher replaces a
 * producer that keeps failing ({@code hoops_outbox_producer_resets_total}).
 */
@QuarkusTest
@TestProfile(ProducerRecoveryTest.SaslBroker.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@WithTestResource(SaslRedpandaResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class ProducerRecoveryTest {

    private static final Duration PATIENCE = Duration.ofSeconds(90);

    /** The broker of {@link SaslRedpandaResource} instead of Dev Services. */
    public static class SaslBroker implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("quarkus.kafka.devservices.enabled", "false");
        }
    }

    @Inject
    OutboxPublisherJob job;

    @Test
    void publishingResumesWithoutARestartOnceTheBrokerUserExists() {
        String tenant = Members.newTenant();
        UUID season = RosterDb.currentSeason(tenant);
        Map<String, UUID> categories = RosterDb.defaultCategories(tenant);
        Members.signIn(tenant, TenantRole.ADMIN);
        UUID lions = UUID.fromString(given().filter(Contract.CORE).header("X-Tenant-Id", tenant)
                .contentType(ContentType.JSON).body("{\"seasonId\":\"" + season + "\",\"name\":\"Lions\",\"ageCategoryId\":\""
                        + categories.get("U12") + "\",\"genderPolicy\":\"MIXED\"}")
                .post("/api/core/teams/").then().statusCode(201).extract().path("id"));

        job.run();

        assertThat(pending(tenant)).as("no broker user yet: nothing is published").isEqualTo(1);
        given().get("/q/health/ready").then().statusCode(200)
                .body("checks.find { it.name == 'outbox-publisher' }.data.state", equalTo("DEGRADED"));

        SaslRedpandaResource.createCoreUser();

        long deadline = System.nanoTime() + PATIENCE.toNanos();
        while (pending(tenant) > 0 && System.nanoTime() < deadline) {
            job.run();
        }

        assertThat(pending(tenant)).as("published without a restart once the user exists").isZero();
        assertThat(TopicReader.of("core.team", tenant)).extracting(Event::key).containsExactly(tenant + ":" + lions);
        given().get("/q/health/ready").then().statusCode(200)
                .body("checks.find { it.name == 'outbox-publisher' }.data.state", equalTo("OK"));
        assertThat(metric("hoops_outbox_producer_resets_total")).isGreaterThanOrEqualTo(1);
    }

    private static long pending(String tenant) {
        return CoreDb.count(tenant, "select count(*) from core.outbox where topic is not null and published_at is null");
    }

    private static double metric(String prefix) {
        String body = given().get("/q/metrics").then().statusCode(200).extract().asString();
        return body.lines().filter(line -> line.startsWith(prefix)).findFirst()
                .map(line -> Double.parseDouble(line.substring(line.lastIndexOf(' ') + 1)))
                .orElseThrow(() -> new AssertionError("no metric " + prefix));
    }
}
