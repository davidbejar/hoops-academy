package com.hoopsacademy.core.adapters.in.rest;

import static com.hoopsacademy.core.testsupport.KeycloakStubs.anyPasswordReset;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSentFor;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSet;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userCreated;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userDeleted;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.PasswordLeaks;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/** {@code POST /api/core/guardians}: a new guardian linked to a player, with a login when an e-mail is given (WP58). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class GuardianResourceTest {

    private static final String GUARDIANS = "/api/core/guardians";
    private static final String LINKS = "/api/core/guardian-links";

    @InjectWireMock
    WireMockServer keycloak;

    private String tenant;
    private UUID player;

    @BeforeEach
    void academyWithAPlayer() {
        KeycloakStubs.installDefaults(keycloak);
        tenant = Members.newTenant();
        UUID kid = CoreDb.person(tenant, null, "Kai", "Kid", null, LocalDate.of(2015, 6, 1), "MALE", TenantRole.PLAYER);
        player = CoreDb.player(tenant, kid);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void aGuardianWithAnEmailGetsALoginWithATemporaryPasswordShownOnce() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        var response = create(guardian("Pia", "pia@example.com")).statusCode(201)
                .header("Cache-Control", "no-store")
                .body("temporaryPassword", notNullValue())
                .body("guardian.displayName", equalTo("Pia Parent"))
                .body("player.id", equalTo(player.toString()))
                .body("player.displayName", equalTo("Kai Kid"))
                .extract();
        String link = response.path("id");
        String guardian = response.path("guardian.personId");
        assertThat(response.header("Location")).endsWith(LINKS + "/" + link);

        keycloak.verify(1, temporaryPasswordSet(sub));
        assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(response.path("temporaryPassword"));
        member(guardian).statusCode(200).body("roles", contains("PARENT"))
                .body("invitationStatus", equalTo("PENDING")).body("userId", notNullValue())
                .body("email", equalTo("pia@example.com"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("playerId", player.toString())
                .get(LINKS).then().statusCode(200).body("items.id", contains(link));
        assertThat(CoreDb.auditActions(tenant))
                .endsWith("member.invited", "guardian_link.created", "member.temporary_password_issued");
        assertThat(CoreDb.auditRow(tenant, "member.temporary_password_issued")).containsEntry("targetId", guardian);
    }

    @Test
    void theTemporaryPasswordOfANewGuardianIsNeverStoredOrLogged() {
        try (LogCapture logs = LogCapture.start()) {
            String password = create(guardian("Sec", "sec.guardian@example.com")).statusCode(201).extract()
                    .path("temporaryPassword");
            PasswordLeaks.assertNeverStoredOrLogged(tenant, password, logs);
        }
    }

    @Test
    void anEmailThatAlreadySignsInElsewhereIsLinkedAndKeepsItsPassword() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.existingUser(keycloak, "shared.parent@example.com", sub);
        String other = Members.newTenant();
        CoreDb.person(other, CoreDb.appUser(sub, "shared.parent@example.com"), "Pia", "Parent",
                "shared.parent@example.com", null, null, TenantRole.PARENT);

        String guardian = create(guardian("Pia", "shared.parent@example.com")).statusCode(201)
                .header("Cache-Control", "no-store")
                .body("$", not(hasKey("temporaryPassword")))
                .extract().path("guardian.personId");

        keycloak.verify(0, userCreated());
        keycloak.verify(0, anyPasswordReset());
        member(guardian).statusCode(200).body("invitationStatus", equalTo("ACCEPTED"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).endsWith("member.invited", "guardian_link.created")
                .doesNotContain("member.temporary_password_issued");
        assertThat(CoreDb.auditActions(other)).isEmpty();
    }

    @Test
    void aGuardianWithoutAnEmailHasNoLogin() {
        String guardian = create("{\"givenName\":\"Nora\",\"familyName\":\"Parent\",\"playerId\":\"" + player + "\"}")
                .statusCode(201).body("$", not(hasKey("temporaryPassword")))
                .body("guardian.displayName", equalTo("Nora Parent"))
                .extract().path("guardian.personId");

        keycloak.verify(0, userCreated());
        member(guardian).statusCode(200).body("userId", nullValue()).body("invitationStatus", equalTo("NONE"))
                .body("roles", contains("PARENT"));
        assertThat(CoreDb.auditActions(tenant)).endsWith("member.invited", "guardian_link.created");
    }

    @Test
    void anUnknownPlayerOrATakenEmailIsRefusedBeforeKeycloak() {
        CoreDb.person(tenant, "Ada", "Admin", "taken@example.com", TenantRole.ADMIN);

        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"P\",\"familyName\":\"Q\",\"email\":\"new@example.com\",\"playerId\":\""
                        + UUID.randomUUID() + "\"}")
                .post(GUARDIANS).then().statusCode(404);
        create(guardian("Dup", "Taken@example.com")).statusCode(409).body("code", equalTo("EMAIL_TAKEN"));

        keycloak.verify(0, userCreated());
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("member.invited", "guardian_link.created");
    }

    @Test
    void keycloakFailuresLeaveNoGuardianBehind() {
        KeycloakStubs.createUserFails(keycloak);
        create(guardian("Kay", "kdown.parent@example.com")).statusCode(502)
                .body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));

        KeycloakStubs.installDefaults(keycloak);
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);
        KeycloakStubs.temporaryPasswordFails(keycloak);
        create(guardian("May", "mfail.parent@example.com")).statusCode(502);

        keycloak.verify(1, userDeleted(sub));
        assertThat(CoreDb.count(tenant, "select count(*) from core.person where email in ('kdown.parent@example.com', "
                + "'mfail.parent@example.com')")).isZero();
        assertThat(CoreDb.count(tenant, "select count(*) from core.guardian_link")).isZero();
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("member.invited", "guardian_link.created",
                "member.temporary_password_issued");
    }

    @Test
    void invalidBodiesAreRejected() {
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"familyName\":\"Q\",\"playerId\":\"" + player + "\"}").post(GUARDIANS).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"P\",\"familyName\":\"Q\",\"email\":\"not-an-email\",\"playerId\":\"" + player
                        + "\"}").post(GUARDIANS).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"P\",\"familyName\":\"Q\"}").post(GUARDIANS).then().statusCode(400);
        keycloak.verify(0, userCreated());
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsAddGuardians(Set<TenantRole> roles, boolean admin) {
        Members.signIn(tenant, roles);
        create("{\"givenName\":\"R\",\"familyName\":\"M\",\"playerId\":\"" + player + "\"}")
                .statusCode(admin ? 201 : 403);
    }

    @Test
    void anotherTenantsPlayerIsNotFound() {
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body(guardian("Eve", "eve.parent@example.com")).post(GUARDIANS).then().statusCode(404);
        keycloak.verify(0, userCreated());
        assertThat(CoreDb.count(other, "select count(*) from core.person")).isZero();
    }

    private String guardian(String givenName, String email) {
        return "{\"givenName\":\"" + givenName + "\",\"familyName\":\"Parent\",\"email\":\"" + email
                + "\",\"locale\":\"en\",\"playerId\":\"" + player + "\"}";
    }

    private ValidatableResponse create(String body) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(body)
                .post(GUARDIANS).then();
    }

    private ValidatableResponse member(String personId) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get("/api/core/members/" + personId).then();
    }
}
