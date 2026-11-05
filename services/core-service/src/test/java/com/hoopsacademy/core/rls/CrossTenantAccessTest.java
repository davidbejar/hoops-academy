package com.hoopsacademy.core.rls;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.DatabaseRoleCheck;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RealLoginProfile;
import com.hoopsacademy.core.testsupport.RosterDb;
import io.agroal.api.AgroalDataSource;
import io.quarkus.arc.Arc;
import io.quarkus.arc.ManagedContext;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.eclipse.microprofile.config.ConfigProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.keycloak.admin.client.CreatedResponseUtil;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.UserRepresentation;
import org.postgresql.util.PSQLException;

/**
 * Tenant isolation end to end, the way an attacker would try it. The admin of academy A logs in through a real
 * Keycloak (password grant, real JWT), the real membership resolver turns the token into a tenant, and every attempt
 * to read academy B's data must come back as 404 (never 403: B's existence is not revealed). The last test goes under
 * the API: in the application's own connection pool, bound to A, Postgres must hide B's rows by itself, which only holds
 * because that pool's role is not a superuser, BYPASSRLS or the table owner.
 *
 * <p>Each test asserts that an attack FAILS. If one of them ever passes the attacker's way, isolation is broken.
 * The sanity test proves the login works, so the 404s below are not an artefact of a broken login.
 * Runs before every commit ({@code .pre-commit-config.yaml}, {@code just isolation-check}); needs Podman.
 */
@Tag("keycloak")
@QuarkusTest
@TestProfile(RealLoginProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(KeycloakContainerResource.class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class CrossTenantAccessTest {

    private static final String SECRET_FAMILY_NAME = "Secretbee";

    @Inject
    Keycloak serviceAccount;

    @Inject
    AgroalDataSource appPool;

    private String academyA;
    private String academyB;
    private UUID ownPlayer;
    private UUID foreignPlayer;
    private UUID foreignTeam;
    private String token;

    @BeforeAll
    void twoAcademiesAndTheAdminOfALoggedIn() throws Exception {
        academyA = Members.newTenant();
        academyB = Members.newTenant();

        String email = "admin-a-" + UUID.randomUUID() + "@example.com";
        String password = "Iso-" + UUID.randomUUID();
        String subject = keycloakUser(email, password);
        CoreDb.person(academyA, CoreDb.login(subject), "Ana", "Admin", email, null, null, TenantRole.ADMIN);
        ownPlayer = RosterDb.player(academyA, "Alba", "Own", LocalDate.of(RosterDb.YEAR - 12, 3, 1), "FEMALE");

        foreignPlayer = RosterDb.player(academyB, "Bruno", SECRET_FAMILY_NAME, LocalDate.of(RosterDb.YEAR - 12, 5, 9), "MALE");
        CoreDb.person(academyB, "Bea", SECRET_FAMILY_NAME, "bea.b@example.com", TenantRole.COACH);
        foreignTeam = RosterDb.team(academyB, RosterDb.currentSeason(academyB), "B Lions",
                RosterDb.defaultCategories(academyB).get("U14"), "MIXED");

        token = passwordGrant(email, password);
    }

    @Test
    void sanityTheLoggedInAdminReadsTheirOwnAcademy() {
        as(academyA).get("/api/core/players").then().statusCode(200).body("items.id", hasItem(ownPlayer.toString()));
    }

    @Test
    void pointingTheTenantHeaderAtAnotherAcademyIsNotFound() {
        as(academyB).get("/api/core/players").then().statusCode(404);
        as(academyB).get("/api/core/players/" + foreignPlayer).then().statusCode(404);
        as(academyB).get("/api/core/members").then().statusCode(404);
        as(academyB).get("/api/core/teams/" + foreignTeam).then().statusCode(404);
        as(academyB).get("/api/core/tenant").then().statusCode(404);
    }

    @Test
    void anotherAcademysRecordsAreNotFoundFromInsideYourOwn() {
        as(academyA).get("/api/core/players/" + foreignPlayer).then().statusCode(404);
        as(academyA).get("/api/core/teams/" + foreignTeam).then().statusCode(404);
        as(academyA).get("/api/core/teams/" + foreignTeam + "/players").then().statusCode(404);
    }

    @Test
    void yourOwnListsNeverContainAnotherAcademysPeople() {
        String players = as(academyA).get("/api/core/players").then().statusCode(200)
                .body("items.id", not(hasItem(foreignPlayer.toString()))).extract().asString();
        String members = as(academyA).get("/api/core/members").then().statusCode(200).extract().asString();
        String search = as(academyA).queryParam("q", SECRET_FAMILY_NAME).get("/api/core/members")
                .then().statusCode(200).extract().asString();

        assertThat(List.of(players, members, search)).noneSatisfy(body -> assertThat(body).contains(SECRET_FAMILY_NAME));
    }

    @Test
    void withoutATokenNothingIsServed() {
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", academyB)
                .get("/api/core/players").then().statusCode(401);
    }

    @Test
    void underTheApiPostgresItselfHidesAnotherAcademysRowsFromTheAppPool() throws SQLException {
        assertThat(count(academyB, "select count(*) from core.player where id = ?", foreignPlayer))
                .as("B's player exists, so a 0 below means hidden, not missing").isEqualTo(1);

        try (Connection c = appPool.getConnection()) {
            assertThat(DatabaseRoleCheck.currentUser(c)).isEqualTo("core_app");
            assertThat(DatabaseRoleCheck.violations(c)).as("the app pool's role must be bound by RLS").isEmpty();

            c.setAutoCommit(false);
            CoreDb.bindTenant(c, TenantId.parse(academyA));
            assertThat(scalar(c, "select count(*) from core.player where id = ?", foreignPlayer)).isZero();
            assertThat(scalar(c, "select count(*) from core.person where family_name = ?", SECRET_FAMILY_NAME)).isZero();
            assertThat(scalar(c, "select count(*) from core.player where id = ?", ownPlayer)).isEqualTo(1);
            c.rollback();

            assertThatThrownBy(() -> scalar(c, "select count(*) from core.player", null))
                    .as("no tenant bound: the policy function raises instead of returning every row")
                    .isInstanceOf(PSQLException.class)
                    .satisfies(e -> assertThat(((PSQLException) e).getSQLState()).isEqualTo("42501"));
            c.rollback();
            c.setAutoCommit(true);
        }
    }

    private RequestSpecification as(String tenant) {
        return given().filter(Contract.CORE).auth().oauth2(token).header("X-Tenant-Id", tenant);
    }

    private static long count(String tenant, String sql, Object param) {
        return CoreDb.inTenant(tenant, c -> scalar(c, sql, param));
    }

    private static long scalar(Connection c, String sql, Object param) throws SQLException {
        try (PreparedStatement statement = c.prepareStatement(sql)) {
            if (param != null) {
                CoreDb.bind(statement, param);
            }
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    private String keycloakUser(String email, String password) {
        CredentialRepresentation credential = new CredentialRepresentation();
        credential.setType(CredentialRepresentation.PASSWORD);
        credential.setValue(password);
        credential.setTemporary(false);
        UserRepresentation user = new UserRepresentation();
        user.setUsername(email);
        user.setEmail(email);
        user.setEmailVerified(true);
        user.setFirstName("Ana");
        user.setLastName("Admin");
        user.setEnabled(true);
        user.setCredentials(List.of(credential));
        ManagedContext requestContext = Arc.container().requestContext(); // the admin client is request-scoped
        requestContext.activate();
        try (Response created = serviceAccount.realm("academy").users().create(user)) {
            assertThat(created.getStatus()).as("Keycloak user created").isEqualTo(201);
            return CreatedResponseUtil.getCreatedId(created);
        } finally {
            requestContext.terminate();
        }
    }

    private static String passwordGrant(String username, String password) throws Exception {
        String url = ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class);
        String form = "grant_type=password&client_id=" + KeycloakContainerResource.DIRECT_GRANT_CLIENT
                + "&username=" + URLEncoder.encode(username, StandardCharsets.UTF_8)
                + "&password=" + URLEncoder.encode(password, StandardCharsets.UTF_8);
        HttpResponse<String> response = HttpClient.newHttpClient().send(HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form)).build(), HttpResponse.BodyHandlers.ofString());
        assertThat(response.statusCode()).as("password grant: %s", response.body()).isEqualTo(200);
        return new ObjectMapper().readTree(response.body()).path("access_token").asText();
    }
}
