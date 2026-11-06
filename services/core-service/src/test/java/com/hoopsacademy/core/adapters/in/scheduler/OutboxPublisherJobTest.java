package com.hoopsacademy.core.adapters.in.scheduler;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.application.port.OutboxQueue;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.DevServicesBroker;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.TopicReader;
import com.hoopsacademy.core.testsupport.TopicReader.Event;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * WP67: the outbox publisher against the Dev Services Redpanda (the pinned image): every pending event goes to its
 * topic once per run, keyed {@code <tenant>:<aggregate>}, in outbox order per aggregate, then is marked published;
 * a crash between send and mark sends the same events again; a broker outage keeps the backlog (the HTTP API keeps
 * working, health says degraded) and the backlog drains when the broker is back.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class OutboxPublisherJobTest {

    private static final String TEAMS = "/api/core/teams/";

    @Inject
    OutboxPublisherJob job;

    @InjectSpy
    OutboxQueue queue;

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;

    @BeforeEach
    void tenantWithSeasonAndLadder() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void publishesEachPendingEventOnceInOutboxOrderKeyedByTenantAndAggregate() {
        UUID lions = createTeam("Lions");
        rename(lions, "Big Lions");
        rename(lions, "Huge Lions");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        request().contentType(ContentType.JSON).body("{\"role\":\"COACH\"}").put(TEAMS + lions + "/staff/" + coach).then()
                .statusCode(200);
        request().delete(TEAMS + lions + "/staff/" + coach).then().statusCode(204);

        job.run();

        List<Event> teams = TopicReader.of("core.team", tenant);
        assertThat(teams).extracting(Event::key).containsOnly(tenant + ":" + lions);
        teams.forEach(event -> RosterEvents.assertValid("core.team", event.json()));
        assertThat(teams).extracting(event -> event.json().get("payload").get("name").asText())
                .containsExactly("Lions", "Big Lions", "Huge Lions");
        assertThat(teams).extracting(event -> event.json().get("eventId").asText())
                .containsExactlyElementsOf(eventIds("core.team", lions));
        assertThat(teams).extracting(event -> event.json().get("tenantId").asText()).containsOnly(tenant);

        List<Event> staff = TopicReader.of("core.team-staff", tenant);
        String staffKey = tenant + ":" + RosterEvents.teamStaffId(lions, coach);
        assertThat(staff).extracting(Event::key).containsOnly(staffKey);
        assertThat(staff).hasSize(3);
        assertThat(staff.get(0).json().get("type").asText()).isEqualTo("team-staff.changed");
        assertThat(staff.get(1).json().get("type").asText()).isEqualTo("team-staff.removed");
        RosterEvents.assertValid("core.team-staff", staff.get(1).json());
        assertThat(staff.get(2).tombstone()).as("the removal is followed by a tombstone").isTrue();
        assertThat(pending(tenant)).isZero();

        job.run();

        assertThat(TopicReader.of("core.team", tenant)).as("a published event is never sent again").hasSize(3);
    }

    @Test
    void aCrashBetweenSendAndMarkSendsTheSameEventsAgain() {
        UUID lions = createTeam("Lions");
        doThrow(new IllegalStateException("crash before the mark")).doCallRealMethod().when(queue).markPublished(any());

        job.run();

        assertThat(TopicReader.of("core.team", tenant)).hasSize(1);
        assertThat(pending(tenant)).as("not marked: the row is sent again").isEqualTo(1);

        job.run();

        List<Event> sent = TopicReader.of("core.team", tenant);
        assertThat(sent).hasSize(2);
        assertThat(sent.get(1).json()).as("the same event, same eventId (consumers drop the duplicate)")
                .isEqualTo(sent.get(0).json());
        assertThat(sent.get(0).json().get("eventId").asText()).isEqualTo(eventIds("core.team", lions).getFirst());
        assertThat(pending(tenant)).isZero();
    }

    @Test
    void aRowLockedByAnotherPublisherHoldsBackTheLaterEventsOfItsAggregateOnly() throws Exception {
        UUID lions = createTeam("Lions");
        rename(lions, "Big Lions");
        UUID cubs = createTeam("Cubs");

        try (Connection otherPublisher = RlsTestDatabase.fromConfig().openAsApp()) {
            otherPublisher.setAutoCommit(false);
            CoreDb.bindTenant(otherPublisher, TenantId.parse(tenant));
            lockFirstEventOf(otherPublisher, lions);

            job.run();

            assertThat(TopicReader.of("core.team", tenant)).extracting(Event::key).containsExactly(tenant + ":" + cubs);
            assertThat(pending(tenant)).as("both events of Lions wait").isEqualTo(2);
            otherPublisher.rollback();
        }

        job.run();

        assertThat(TopicReader.of("core.team", tenant)).extracting(event -> event.json().get("payload").get("name").asText())
                .containsExactly("Cubs", "Lions", "Big Lions");
    }

    @Test
    void aBrokerOutageKeepsTheBacklogAndTheApiAndDrainsWhenTheBrokerIsBack() {
        DevServicesBroker.pause();
        UUID lions;
        try {
            lions = createTeam("Lions");

            job.run();

            assertThat(pending(tenant)).isEqualTo(1);
            given().get("/q/health/ready").then().statusCode(200).body("status", equalTo("UP"))
                    .body("checks.find { it.name == 'outbox-publisher' }.status", equalTo("UP"))
                    .body("checks.find { it.name == 'outbox-publisher' }.data.state", equalTo("DEGRADED"));
            assertThat(metric("hoops_outbox_pending")).isGreaterThanOrEqualTo(1);
            assertThat(metric("hoops_outbox_broker_available")).isZero();
        } finally {
            DevServicesBroker.resume();
        }

        job.run();

        assertThat(TopicReader.of("core.team", tenant)).extracting(Event::key).containsExactly(tenant + ":" + lions);
        assertThat(pending(tenant)).isZero();
        given().get("/q/health/ready").then().statusCode(200)
                .body("checks.find { it.name == 'outbox-publisher' }.data.state", equalTo("OK"));
        assertThat(metric("hoops_outbox_broker_available")).isEqualTo(1);
        assertThat(metric("hoops_outbox_published_total{topic=\"core.team\"")).isGreaterThanOrEqualTo(1);
        assertThat(metric("hoops_outbox_lag_seconds")).isGreaterThanOrEqualTo(0);
    }

    private UUID createTeam(String name) {
        return UUID.fromString(request().contentType(ContentType.JSON).body("{\"seasonId\":\"" + season + "\",\"name\":\""
                + name + "\",\"ageCategoryId\":\"" + categories.get("U12") + "\",\"genderPolicy\":\"MIXED\"}")
                .post(TEAMS).then().statusCode(201).extract().path("id"));
    }

    private void rename(UUID team, String name) {
        request().contentType(ContentType.JSON).body("{\"name\":\"" + name + "\"}").patch(TEAMS + team).then()
                .statusCode(200);
    }

    private List<String> eventIds(String topic, UUID aggregate) {
        return RosterEvents.of(tenant, topic, aggregate).stream().map(event -> event.get("eventId").asText()).toList();
    }

    private static long pending(String tenant) {
        return CoreDb.count(tenant, "select count(*) from core.outbox where topic is not null and published_at is null");
    }

    private static void lockFirstEventOf(Connection connection, UUID aggregate) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "select id from core.outbox where aggregate_id = ? order by seq limit 1 for update")) {
            statement.setString(1, aggregate.toString());
            try (ResultSet rs = statement.executeQuery()) {
                assertThat(rs.next()).isTrue();
            }
        }
    }

    /** The value of the first sample whose name (with the start of its labels) begins with {@code prefix}. */
    private static double metric(String prefix) {
        String body = given().get("/q/metrics").then().statusCode(200).extract().asString();
        return body.lines().filter(line -> line.startsWith(prefix)).findFirst()
                .map(line -> Double.parseDouble(line.substring(line.lastIndexOf(' ') + 1)))
                .orElseThrow(() -> new AssertionError("no metric " + prefix));
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }
}
