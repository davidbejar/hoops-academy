package com.hoopsacademy.core.adapters.in.platform;

import static com.hoopsacademy.core.testsupport.KeycloakStubs.anySetupEmail;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.anyUserDeleted;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.setupEmailSent;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userCreated;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userDeleted;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.FailingProvisioningHook;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Slugs;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformTenantResourceTest {

    private static final String TENANTS = "/platform/tenants";

    @InjectWireMock
    WireMockServer keycloak;

    @BeforeEach
    void resetKeycloak() {
        KeycloakStubs.installDefaults(keycloak);
    }

    // ------------------------------------------------------------------ create

    @Test
    void createTenantProvisionsTheFirstAdminAndSendsTheSetupEmail() {
        String slug = Slugs.unique("acme");
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        var response = given().filter(Contract.CORE).contentType(ContentType.JSON)
                .body(createBody(slug, slug + ".ana@example.com"))
                .when().post(TENANTS)
                .then().statusCode(201)
                .body("slug", equalTo(slug))
                .body("status", equalTo("ACTIVE"))
                .body("timezone", equalTo("Europe/Madrid"))
                .body("defaultLocale", equalTo("es"))
                .body("suspendedAt", nullValue())
                .extract();
        String id = response.path("id");
        assertThat(response.header("Location")).endsWith(TENANTS + "/" + id);

        keycloak.verify(1, userCreated());
        keycloak.verify(1, setupEmailSent(sub));
        assertThat(CoreDb.count(id, "select count(*) from core.tenant_settings")).isEqualTo(1);
        assertThat(CoreDb.count(id, """
                select count(*) from core.age_category
                 where (code, max_age, sort_rank) in (('U8', 7, 0), ('U10', 9, 1), ('U12', 11, 2), ('U14', 13, 3),
                                                      ('U16', 15, 4), ('U18', 17, 5))
                    or (code = 'SENIOR' and max_age is null and sort_rank = 6)""")).isEqualTo(7);
        assertThat(CoreDb.count(id, "select count(*) from core.age_category")).isEqualTo(7);
        assertThat(CoreDb.count(id, """
                select count(*) from core.person p
                  join core.membership_role r on r.person_id = p.id and r.role = 'ADMIN'
                  join core.app_user u on u.id = p.user_id and u.keycloak_sub = ?
                 where p.invitation_status = 'PENDING'""", sub)).isEqualTo(1);
        assertThat(CoreDb.count(id, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
        assertThat(CoreDb.count(id, "select count(*) from core.outbox where event_type in ('tenant.created', 'member.invited')"))
                .isEqualTo(2);
        assertThat(CoreDb.countAsPlatform("select count(*) from billing.tenant_subscription where tenant_id = ?::uuid "
                + "and plan_code = 'FREE'", id)).isEqualTo(1);
        assertThat(CoreDb.auditActions(id)).containsExactly("tenant.created", "member.invited");
        assertThat(CoreDb.auditRow(id, "tenant.created")).containsEntry("targetId", id)
                .containsEntry("actorSub", "platform-admin");
    }

    @Test
    void createTenantReusesAnExistingKeycloakUserWithoutEmail() {
        String slug = Slugs.unique("reuse");
        String email = slug + ".coach@example.com";
        String existingSub = UUID.randomUUID().toString();
        KeycloakStubs.existingUser(keycloak, email, existingSub);

        String id = given().filter(Contract.CORE).contentType(ContentType.JSON).body(createBody(slug, email))
                .post(TENANTS).then().statusCode(201).extract().path("id");

        keycloak.verify(0, userCreated());
        keycloak.verify(0, anySetupEmail());
        assertThat(CoreDb.count(id, """
                select count(*) from core.person p join core.app_user u on u.id = p.user_id
                 where u.keycloak_sub = ? and p.invitation_status = 'ACCEPTED'""", existingSub)).isEqualTo(1);
    }

    @Test
    void duplicateSlugIsAConflictAndTouchesNoKeycloakUser() {
        String slug = Slugs.unique("dup");
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(createBody(slug, slug + ".a@example.com"))
                .post(TENANTS).then().statusCode(201);
        KeycloakStubs.installDefaults(keycloak);

        given().filter(Contract.CORE).contentType(ContentType.JSON).body(createBody(slug, slug + ".b@example.com"))
                .post(TENANTS).then().statusCode(409).contentType("application/problem+json")
                .body("code", equalTo("SLUG_TAKEN"));
        keycloak.verify(0, userCreated());
    }

    @Test
    void keycloakFailureLeavesNoTenantBehind() {
        String slug = Slugs.unique("kcdown");
        KeycloakStubs.createUserFails(keycloak);

        given().filter(Contract.FAILURES).contentType(ContentType.JSON).body(createBody(slug, slug + ".a@example.com"))
                .post(TENANTS).then().statusCode(502).contentType("application/problem+json")
                .body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));

        assertThat(CoreDb.countAsPlatform("select count(*) from core.tenant where slug = ?", slug)).isZero();
    }

    @Test
    void setupEmailFailureRollsBackTheTenantAndDeletesTheNewKeycloakUser() {
        String slug = Slugs.unique("mailfail");
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);
        KeycloakStubs.setupEmailFails(keycloak);

        given().filter(Contract.FAILURES).contentType(ContentType.JSON).body(createBody(slug, slug + ".a@example.com"))
                .post(TENANTS).then().statusCode(502);

        assertThat(CoreDb.countAsPlatform("select count(*) from core.tenant where slug = ?", slug)).isZero();
        assertThat(CoreDb.count(null, "select count(*) from core.app_user where keycloak_sub = ?", sub)).isZero();
        keycloak.verify(1, userDeleted(sub));
    }

    @Test
    void databaseFailureAfterKeycloakRollsBackAndCompensatesTheKeycloakUser() {
        String slug = Slugs.unique(FailingProvisioningHook.SLUG_PREFIX);
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        given().filter(Contract.FAILURES).contentType(ContentType.JSON).body(createBody(slug, slug + ".a@example.com"))
                .post(TENANTS).then().statusCode(500).contentType("application/problem+json");

        assertThat(CoreDb.countAsPlatform("select count(*) from core.tenant where slug = ?", slug)).isZero();
        keycloak.verify(1, userDeleted(sub));
        keycloak.verify(0, anySetupEmail());
    }

    @Test
    void anExistingKeycloakUserIsNeverDeletedByTheCompensation() {
        String slug = Slugs.unique(FailingProvisioningHook.SLUG_PREFIX);
        String email = slug + ".kept@example.com";
        KeycloakStubs.existingUser(keycloak, email, UUID.randomUUID().toString());

        given().filter(Contract.FAILURES).contentType(ContentType.JSON).body(createBody(slug, email))
                .post(TENANTS).then().statusCode(500);
        keycloak.verify(0, anyUserDeleted());
    }

    @Test
    void invalidRequestsAreRejected() {
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON)
                .body("{\"slug\":\"ok-slug\",\"name\":\"x\",\"timezone\":\"UTC\",\"defaultLocale\":\"es\"}")
                .post(TENANTS).then().statusCode(400).body("violations.field", hasItem(endsWith("firstAdmin")));
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON)
                .body(createBody("Bad Slug", "a@example.com")).post(TENANTS).then().statusCode(400);
        given().filter(Contract.CORE).contentType(ContentType.JSON)
                .body(createBody(Slugs.unique("tz"), "a@example.com").replace("Europe/Madrid", "Mars/Olympus"))
                .post(TENANTS).then().statusCode(422).body("code", equalTo("INVALID_TIMEZONE"));
        keycloak.verify(0, userCreated());
    }

    // ------------------------------------------------------------------ read / update / lifecycle

    @Test
    void getListAndUpdateTenants() {
        String id = createTenant(Slugs.unique("read"));

        given().filter(Contract.CORE).get(TENANTS + "/" + id).then().statusCode(200).body("id", equalTo(id));
        given().filter(Contract.CORE).queryParam("q", "READ-").queryParam("status", "ACTIVE").queryParam("size", 200)
                .get(TENANTS).then().statusCode(200)
                .body("items.id", hasItem(id))
                .body("items.status", everyItem(equalTo("ACTIVE")))
                .body("page.size", equalTo(200))
                .body("page.totalElements", greaterThanOrEqualTo(1));
        given().filter(Contract.CORE).contentType(ContentType.JSON).body("{\"name\":\"Renamed Academy\",\"defaultLocale\":\"id\"}")
                .patch(TENANTS + "/" + id).then().statusCode(200)
                .body("name", equalTo("Renamed Academy"))
                .body("defaultLocale", equalTo("id"))
                .body("timezone", equalTo("Europe/Madrid"));
        assertThat(CoreDb.auditRow(id, "tenant.master_data_changed").get("metadata")).contains("name", "defaultLocale");
        given().filter(Contract.CORE).get(TENANTS + "/" + UUID.randomUUID()).then().statusCode(404);
    }

    @Test
    void suspendReactivateWithdraw() {
        String id = createTenant(Slugs.unique("life"));
        String reason = "{\"reason\":\"unpaid invoice\"}";

        given().filter(Contract.CORE).contentType(ContentType.JSON).body(reason).post(TENANTS + "/" + id + "/suspend")
                .then().statusCode(200).body("status", equalTo("SUSPENDED")).body("suspendedAt", notNullValue());
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(reason).post(TENANTS + "/" + id + "/suspend")
                .then().statusCode(409).body("code", equalTo("TENANT_NOT_ACTIVE"));
        given().filter(Contract.CORE).post(TENANTS + "/" + id + "/reactivate")
                .then().statusCode(200).body("status", equalTo("ACTIVE"));
        given().filter(Contract.CORE).post(TENANTS + "/" + id + "/reactivate")
                .then().statusCode(409).body("code", equalTo("TENANT_NOT_SUSPENDED"));
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(reason).post(TENANTS + "/" + id + "/withdraw")
                .then().statusCode(200).body("status", equalTo("WITHDRAWN")).body("retainUntil", notNullValue());
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(reason).post(TENANTS + "/" + id + "/withdraw")
                .then().statusCode(409);
        given().filter(Contract.CORE).post(TENANTS + "/" + UUID.randomUUID() + "/reactivate").then().statusCode(404);

        assertThat(CoreDb.count(id, "select count(*) from core.outbox where event_type in "
                + "('tenant.suspended', 'tenant.reactivated', 'tenant.withdrawn')")).isEqualTo(3);
        assertThat(CoreDb.auditActions(id)).as("failed transitions are not audited")
                .endsWith("tenant.suspended", "tenant.reactivated", "tenant.withdrawn");
        assertThat(CoreDb.auditRow(id, "tenant.suspended").get("metadata")).contains("unpaid invoice");
    }

    @Test
    void usageAggregatesTheServicesAndListsTheUnavailableOnes() {
        String id = createTenant(Slugs.unique("usage"));

        given().filter(Contract.CORE).get(TENANTS + "/" + id + "/usage").then().statusCode(200)
                .body("tenantId", equalTo(id))
                .body("services.service", containsInAnyOrder("core", "game"))
                .body("services.find { it.service == 'core' }.counters.members", equalTo(1))
                .body("services.find { it.service == 'game' }.counters.matches", equalTo(3))
                .body("unavailableServices", containsInAnyOrder("athlete"));
        assertThat(CoreDb.countAsPlatform("select count(*) from core.usage_snapshot where tenant_id = ?::uuid", id))
                .isEqualTo(1);
        given().filter(Contract.CORE).get(TENANTS + "/" + UUID.randomUUID() + "/usage").then().statusCode(404);
    }

    // ------------------------------------------------------------------ authorization

    @Test
    @TestSecurity(user = "academy-admin", roles = "user")
    void nonSuperAdminIsForbidden() {
        given().filter(Contract.CORE).get(TENANTS).then().statusCode(403).contentType("application/problem+json");
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body(createBody("x-forbidden", "a@example.com"))
                .post(TENANTS).then().statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousIsUnauthorized() {
        given().filter(Contract.CORE).get(TENANTS).then().statusCode(401).contentType("application/problem+json");
    }

    private String createTenant(String slug) {
        return given().contentType(ContentType.JSON).body(createBody(slug, slug + ".admin@example.com"))
                .post(TENANTS).then().statusCode(201).extract().path("id");
    }

    static String createBody(String slug, String email) {
        return """
                {"slug":"%s","name":"Academy %s","timezone":"Europe/Madrid","defaultLocale":"es",
                 "firstAdmin":{"email":"%s","givenName":"Ana","familyName":"García","locale":"es"}}
                """.formatted(slug, slug, email);
    }
}
