package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * WP96 (decision 70): a player's preferred jersey number. ADMIN and COACH set it, a PARENT for a linked player and a
 * PLAYER for themselves as a wish; everyone who reads the player reads it.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class PlayerPreferredJerseyTest {

    private static final String PLAYERS = "/api/core/players/";

    private String tenant;
    private UUID uma;

    @BeforeEach
    void aPlayer() {
        tenant = Members.newTenant();
        RosterDb.currentSeason(tenant);
        uma = RosterDb.playerAged(tenant, "Uma", 11, "FEMALE");
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void anAdminSetsChangesAndClearsThePreferredNumber() {
        request().get(PLAYERS + uma).then().statusCode(200).body("preferredJerseyNumber", nullValue());

        patch(uma, "{\"preferredJerseyNumber\":\"7\"}").statusCode(200).body("id", equalTo(uma.toString()))
                .body("preferredJerseyNumber", equalTo("7"));
        request().get(PLAYERS + uma).then().body("preferredJerseyNumber", equalTo("7"));
        request().get("/api/core/players").then().body("items.preferredJerseyNumber", contains("7"));
        patch(uma, "{\"preferredJerseyNumber\":\"07\"}").statusCode(200).body("preferredJerseyNumber", equalTo("07"));
        patch(uma, "{\"clear\":[\"preferredJerseyNumber\"]}").statusCode(200).body("preferredJerseyNumber", nullValue());
        assertThat(RosterDb.text(tenant, "select preferred_jersey_number from core.player where id = ?", uma)).isNull();
    }

    @Test
    void thePreferenceIsNotUniqueAndWritesNoAuditRowAndNoEvent() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        long events = RosterEvents.count(tenant);
        int audit = CoreDb.auditActions(tenant).size();

        patch(uma, "{\"preferredJerseyNumber\":\"23\"}").statusCode(200);
        patch(ben, "{\"preferredJerseyNumber\":\"23\"}").statusCode(200).body("preferredJerseyNumber", equalTo("23"));
        patch(ben, "{\"preferredJerseyNumber\":\"23\"}").statusCode(200).body("preferredJerseyNumber", equalTo("23"));

        assertThat(RosterEvents.count(tenant)).as("core.player does not carry the preference").isEqualTo(events);
        assertThat(CoreDb.auditActions(tenant)).hasSize(audit);
    }

    @Test
    void invalidBodiesAreRejected() {
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"preferredJerseyNumber\":\"100\"}").patch(PLAYERS + uma).then().statusCode(400)
                .body("violations.field", contains("preferredJerseyNumber"));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{}").patch(PLAYERS + uma).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"preferredJerseyNumber\":\"5\",\"clear\":[\"preferredJerseyNumber\"]}").patch(PLAYERS + uma)
                .then().statusCode(400).body("violations.code", contains("CLEAR_CONFLICT"));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"Una\"}").patch(PLAYERS + uma).then().statusCode(400);
        patch(UUID.randomUUID(), "{\"preferredJerseyNumber\":\"5\"}").statusCode(404);
    }

    /** roles, linked to / is the player?, expected status (authz matrix row "Preferred jersey number"). */
    static Stream<Arguments> callers() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), false, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH), false, 200),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), false, 403),
                Arguments.of(EnumSet.of(TenantRole.PARENT), true, 200),
                Arguments.of(EnumSet.of(TenantRole.PARENT), false, 404),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), true, 200),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), false, 404),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), false, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), false, 200),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH, TenantRole.PARENT), true, 200),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH, TenantRole.PARENT), false, 403));
    }

    @ParameterizedTest
    @MethodSource("callers")
    void roleMatrix(Set<TenantRole> roles, boolean related, int expected) {
        signInWith(roles, related);

        patch(uma, "{\"preferredJerseyNumber\":\"11\"}").statusCode(expected);

        String stored = RosterDb.text(tenant, "select preferred_jersey_number from core.player where id = ?", uma);
        assertThat(stored).isEqualTo(expected == 200 ? "11" : null);
        if (expected != 404) {
            request().get(PLAYERS + uma).then().statusCode(200).body("preferredJerseyNumber",
                    expected == 200 ? equalTo("11") : nullValue());
        }
    }

    @Test
    void anotherTenantsPlayerIsNotFound() {
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);

        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body("{\"preferredJerseyNumber\":\"5\"}").patch(PLAYERS + uma).then().statusCode(404);
        assertThat(RosterDb.text(tenant, "select preferred_jersey_number from core.player where id = ?", uma)).isNull();
    }

    private void signInWith(Set<TenantRole> roles, boolean related) {
        boolean parent = roles.contains(TenantRole.PARENT) && related;
        boolean self = roles.contains(TenantRole.PLAYER) && related;
        TenantUserRegistry.clear();
        TenantUserRegistry.register(new AuthzContext(TenantUser.SUBJECT, Members.callerPersonId(tenant),
                TenantId.parse(tenant), roles, Set.of(), parent ? Set.of(uma) : Set.of(),
                self ? Optional.of(uma) : Optional.empty()));
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse patch(UUID player, String body) {
        return request().contentType(ContentType.JSON).body(body).patch(PLAYERS + player).then();
    }
}
