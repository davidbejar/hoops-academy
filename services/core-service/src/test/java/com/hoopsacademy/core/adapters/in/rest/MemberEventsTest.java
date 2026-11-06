package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** WP67: the member, guardian-link and academy-profile use cases append their aggregate's state to the outbox. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class MemberEventsTest {

    private static final String MEMBERS = "/api/core/members";

    @InjectWireMock
    WireMockServer keycloak;

    private String tenant;

    @BeforeEach
    void tenantWithOneAdmin() {
        KeycloakStubs.installDefaults(keycloak);
        tenant = Members.newTenant();
        CoreDb.person(tenant, "Ada", "Admin", "ada@example.com", TenantRole.ADMIN);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void invitingAMemberPublishesThePersonWithItsLoginAndSortedRoles() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        UUID carla = UUID.fromString(request().contentType(ContentType.JSON).body("""
                {"givenName":"Carla","familyName":"Coach","email":"carla@example.com","roles":["PARENT","COACH"]}""")
                .post(MEMBERS).then().statusCode(201).extract().path("personId"));

        JsonNode event = RosterEvents.last(tenant, "core.person", carla);
        assertThat(event.get("type").asText()).isEqualTo("person.changed");
        assertThat(event.get("tenantId").asText()).isEqualTo(tenant);
        assertThat(event.get("payload").get("displayName").asText()).isEqualTo("Carla Coach");
        assertThat(event.get("payload").get("subject").asText()).isEqualTo(sub);
        assertThat(roles(event.get("payload"))).containsExactly("COACH", "PARENT");
        assertThat(event.get("payload").get("active").asBoolean()).isTrue();
        assertThat(RosterEvents.of(tenant, "core.player")).isEmpty();
    }

    @Test
    void invitingAPlayerPublishesThePersonAndThePlayer() {
        UUID leo = UUID.fromString(request().contentType(ContentType.JSON).body("""
                {"givenName":"Leo","familyName":"Kid","birthDate":"2015-02-28","gender":"MALE","roles":["PLAYER"],
                 "sendInvitation":false}""").post(MEMBERS).then().statusCode(201).extract().path("personId"));
        UUID player = playerOf(leo);

        assertThat(RosterEvents.state(tenant, "core.person", leo).get("subject").isNull()).isTrue();
        JsonNode state = RosterEvents.state(tenant, "core.player", player);
        assertThat(state.get("personId").asText()).isEqualTo(leo.toString());
        assertThat(state.get("displayName").asText()).isEqualTo("Leo Kid");
        assertThat(state.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(state.get("birthDate").asText()).isEqualTo("2015-02-28");
        assertThat(state.get("gender").asText()).isEqualTo("MALE");
    }

    @Test
    void editingAPlayersPersonalDataRepublishesThePlayerToo() {
        UUID leo = CoreDb.person(tenant, null, "Leo", "Kid", null, LocalDate.of(2014, 1, 1), "MALE", TenantRole.PLAYER);
        UUID player = CoreDb.player(tenant, leo);

        patch(leo, "{\"givenName\":\"Leon\",\"birthDate\":\"2014-02-02\"}");

        assertThat(RosterEvents.state(tenant, "core.person", leo).get("displayName").asText()).isEqualTo("Leon Kid");
        JsonNode state = RosterEvents.state(tenant, "core.player", player);
        assertThat(state.get("displayName").asText()).isEqualTo("Leon Kid");
        assertThat(state.get("birthDate").asText()).isEqualTo("2014-02-02");
    }

    @Test
    void grantingThePlayerRoleCreatesAndPublishesThePlayer() {
        UUID pam = CoreDb.person(tenant, null, "Pam", "Parent", null, LocalDate.of(2010, 5, 5), "FEMALE", TenantRole.PARENT);

        request().contentType(ContentType.JSON).body("{\"roles\":[\"PARENT\",\"PLAYER\"]}")
                .put(MEMBERS + "/" + pam + "/roles").then().statusCode(200);

        assertThat(roles(RosterEvents.state(tenant, "core.person", pam))).containsExactly("PARENT", "PLAYER");
        assertThat(RosterEvents.state(tenant, "core.player", playerOf(pam)).get("status").asText()).isEqualTo("ACTIVE");
    }

    @Test
    void deactivatingAMemberPublishesItInactive() {
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", "cora@example.com", TenantRole.COACH);

        request().post(MEMBERS + "/" + coach + "/deactivate").then().statusCode(200);

        assertThat(RosterEvents.state(tenant, "core.person", coach).get("active").asBoolean()).isFalse();
    }

    @Test
    void linkingAndUnlinkingAGuardianPublishesTheLinkThenItsRemoval() {
        UUID pam = CoreDb.person(tenant, "Pam", "Parent", null, TenantRole.PARENT);
        UUID kid = CoreDb.person(tenant, null, "Leo", "Kid", null, LocalDate.of(2014, 1, 1), "MALE", TenantRole.PLAYER);
        UUID player = CoreDb.player(tenant, kid);

        UUID link = UUID.fromString(request().contentType(ContentType.JSON)
                .body("{\"guardianPersonId\":\"" + pam + "\",\"playerId\":\"" + player + "\"}")
                .post("/api/core/guardian-links").then().statusCode(201).extract().path("id"));
        JsonNode linked = RosterEvents.last(tenant, "core.guardian-link", link);
        assertThat(linked.get("type").asText()).isEqualTo("guardian-link.changed");
        assertThat(linked.get("payload").get("guardianPersonId").asText()).isEqualTo(pam.toString());
        assertThat(linked.get("payload").get("playerId").asText()).isEqualTo(player.toString());

        request().delete("/api/core/guardian-links/" + link).then().statusCode(204);

        JsonNode removed = RosterEvents.last(tenant, "core.guardian-link", link);
        assertThat(removed.get("type").asText()).isEqualTo("guardian-link.removed");
        assertThat(removed.get("payload")).isEqualTo(linked.get("payload"));
    }

    @Test
    void editingTheAcademyProfilePublishesTheTenant() {
        request().contentType(ContentType.JSON).body("{\"name\":\"Lions Academy\",\"timezone\":\"Asia/Jakarta\"}")
                .patch("/api/core/tenant").then().statusCode(200);
        request().contentType(ContentType.JSON).body("{\"contactEmail\":\"hello@example.com\"}")
                .patch("/api/core/tenant").then().statusCode(200);

        List<JsonNode> events = RosterEvents.of(tenant, "core.tenant");
        assertThat(events).hasSize(2);
        JsonNode event = events.getLast();
        assertThat(event.get("aggregateId").asText()).isEqualTo(tenant);
        assertThat(event.get("payload").get("name").asText()).isEqualTo("Lions Academy");
        assertThat(event.get("payload").get("timezone").asText()).isEqualTo("Asia/Jakarta");
        assertThat(event.get("payload").get("status").asText()).isEqualTo("ACTIVE");
    }

    private UUID playerOf(UUID person) {
        return UUID.fromString(com.hoopsacademy.core.testsupport.RosterDb.text(tenant,
                "select id::text from core.player where person_id = ?", person));
    }

    private void patch(UUID person, String body) {
        request().contentType(ContentType.JSON).body(body).patch(MEMBERS + "/" + person).then().statusCode(200);
    }

    private static List<String> roles(JsonNode payload) {
        return java.util.stream.StreamSupport.stream(payload.get("roles").spliterator(), false).map(JsonNode::asText)
                .toList();
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }
}
