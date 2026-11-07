package com.hoopsacademy.core.adapters.in.platform;

import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSentFor;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userCreated;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.PasswordLeaks;
import com.hoopsacademy.core.testsupport.Slugs;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.mailer.Mail;
import io.quarkus.mailer.MockMailbox;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import jakarta.inject.Inject;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Invitation-only sign-up (WP90, ADR-0044): the public request and the super admin's decisions. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformAcademyRequestResourceTest {

    private static final String REQUESTS = "/platform/academy-requests";

    @InjectWireMock
    WireMockServer keycloak;

    @Inject
    MockMailbox mailbox;

    @BeforeEach
    void reset() {
        KeycloakStubs.installDefaults(keycloak);
        mailbox.clear();
    }

    // ------------------------------------------------------------------ public request

    @Test
    @TestSecurity
    void anyoneMayRequestAnAcademyAndGetsNothingButReceived() {
        String academy = unique("Norte Basket");
        String email = email("ana");

        submit(body("Ana Ruiz", email, "COACH", academy, "es")).statusCode(202).body("status", equalTo("RECEIVED"));

        assertThat(CoreDb.countAsPlatform("""
                select count(*) from core.academy_request
                 where academy_name = ? and email = ? and requester_name = 'Ana Ruiz' and requester_role = 'COACH'
                   and locale = 'es' and status = 'PENDING' and decided_at is null""", academy, email)).isEqualTo(1);
        assertThat(mailbox.getTotalMessagesSent()).as("nothing is e-mailed on submission").isZero();
    }

    @Test
    @TestSecurity
    void theNameIsOptionalAndTheLanguageDefaultsToEnglish() {
        String academy = unique("No Name Club");

        submit("{\"email\":\"" + email("x") + "\",\"role\":\"PARENT\",\"academyName\":\"" + academy
                + "\"}").statusCode(202);

        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where academy_name = ? "
                + "and requester_name is null and locale = 'en'", academy)).isEqualTo(1);
    }

    @Test
    @TestSecurity
    void aFilledHoneypotIsAnsweredTheSameAndDropped() {
        String academy = unique("Bot Academy");

        submit(body("Bot", "bot@example.com", "ADMIN", academy, "en").replace("}", ",\"website\":\"http://spam\"}"))
                .statusCode(202).body("status", equalTo("RECEIVED"));

        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where academy_name = ?",
                academy)).isZero();
    }

    @Test
    @TestSecurity
    void anEmptyHoneypotIsNoBot() {
        String academy = unique("Human Academy");

        submit(body(null, email("h"), "ADMIN", academy, "en").replace("}", ",\"website\":\"\"}"))
                .statusCode(202);

        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where academy_name = ?",
                academy)).isEqualTo(1);
    }

    @Test
    @TestSecurity
    void theNameOfAnExistingAcademyIsTakenWhateverTheCaseAndSpacing() {
        String academy = unique("Existing Club");
        academyNamed(academy);

        submit(body(null, "a@example.com", "ADMIN", "  " + academy.toUpperCase().replace(" ", "   "), "en"))
                .statusCode(409).contentType("application/problem+json").body("code", equalTo("ACADEMY_NAME_TAKEN"));
    }

    @Test
    void aPendingRequestHoldsItsNameAndARejectedOneFreesIt() {
        String academy = unique("Held Club");
        submit(body(null, email("a"), "ADMIN", academy, "en")).statusCode(202);

        submit(body(null, email("b"), "COACH", academy.toLowerCase(), "en")).statusCode(409)
                .body("code", equalTo("ACADEMY_NAME_TAKEN"));

        reject(requestId(academy), "Duplicate").statusCode(200);
        submit(body(null, email("b"), "COACH", academy, "en")).statusCode(202);
    }

    @Test
    @TestSecurity
    void aFourthPendingRequestOfOneEmailIsDroppedSilently() {
        String email = email("busy").replace("example", "Example");
        for (int i = 0; i < 4; i++) {
            submit(body(null, i == 3 ? email.toLowerCase() : email, "ADMIN", unique("Busy " + i), "en"))
                    .statusCode(202).body("status", equalTo("RECEIVED"));
        }

        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where lower(email) = lower(?)",
                email)).isEqualTo(3);
    }

    @Test
    @TestSecurity
    void malformedRequestsAre400WithoutDetailsOfTheServer() {
        String ok = unique("Valid Club");
        for (String invalid : List.of(
                "{\"role\":\"ADMIN\",\"academyName\":\"" + ok + "\"}",
                body(null, "not-an-email", "ADMIN", ok, "en"),
                body(null, "a@example.com", "PLAYER", ok, "en"),
                body(null, "a@example.com", "ADMIN", "x".repeat(121), "en"),
                body(null, "a@example.com", "ADMIN", "   ", "en"),
                body("n".repeat(121), "a@example.com", "ADMIN", ok, "en"),
                body(null, "a@example.com", "ADMIN", ok, "fr"),
                body("Ana\\u0000", "a@example.com", "ADMIN", ok, "en"),
                body(null, "a@example.com", "ADMIN", "Club\\nBcc: x", "en"),
                body(null, "a@example.com", "ADMIN", "Club\\u202E", "en"))) {
            given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body(invalid).post(REQUESTS)
                    .then().statusCode(400).contentType("application/problem+json")
                    .body("$", not(hasKey("stackTrace")));
        }
        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where academy_name = ?", ok))
                .isZero();
    }

    // ------------------------------------------------------------------ workbench authorization

    @Test
    @TestSecurity
    void anonymousCallersCannotListOrDecide() {
        given().filter(Contract.CORE).get(REQUESTS).then().statusCode(401).contentType("application/problem+json");
        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).contentType(ContentType.JSON).body("{\"reason\":\"x\"}")
                .post(REQUESTS + "/" + UUID.randomUUID() + ":reject").then().statusCode(401);
    }

    @Test
    @TestSecurity(user = "coach", roles = "user")
    void signedInUsersWithoutTheSuperAdminRoleCannotListOrDecide() {
        given().filter(Contract.CORE).get(REQUESTS).then().statusCode(403);
        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).contentType(ContentType.JSON).body(acceptBody("x-slug"))
                .post(REQUESTS + "/" + UUID.randomUUID() + ":accept").then().statusCode(403);
    }

    @Test
    void theSuperAdminListsByStatusNewestFirst() {
        String first = unique("List One");
        String second = unique("List Two");
        submitAnonymously(first, "es");
        submitAnonymously(second, "id");
        reject(requestId(first), "No").statusCode(200);

        given().filter(Contract.CORE).queryParam("status", "PENDING").queryParam("size", 200).get(REQUESTS)
                .then().statusCode(200).body("items.status", everyItem(equalTo("PENDING")))
                .body("items.academyName", hasItem(second)).body("items.academyName", not(hasItem(first)));
        given().filter(Contract.CORE).queryParam("status", "REJECTED").queryParam("size", 200).get(REQUESTS)
                .then().statusCode(200).body("items.find { it.academyName == '" + first + "' }.reason", equalTo("No"));
        List<String> all = given().filter(Contract.CORE).queryParam("size", 2).get(REQUESTS).then().statusCode(200)
                .body("page.size", equalTo(2)).extract().path("items.academyName");
        assertThat(all).containsExactly(second, first);
        given().filter(Contract.RESPONSES_ONLY).queryParam("status", "OPEN").get(REQUESTS).then().statusCode(400);
    }

    // ------------------------------------------------------------------ accept

    @Test
    void acceptingCreatesTheAcademyWithTheRequesterAsFirstAdminAndShowsThePasswordOnce() {
        String academy = unique("Accepted Club");
        String email = email("lead");
        submitAnonymously(academy, email, "COACH", "es");
        String id = requestId(academy);
        String slug = Slugs.unique("accepted");
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        ValidatableResponse accepted;
        String password;
        String tenant;
        try (LogCapture logs = LogCapture.start()) {
            accepted = accept(id, acceptBody(slug)).statusCode(200).header("Cache-Control", "no-store")
                    .body("request.status", equalTo("ACCEPTED"))
                    .body("request.decidedBy", equalTo("platform-admin"))
                    .body("request.decidedAt", notNullValue())
                    .body("request.notifiedAt", notNullValue())
                    .body("tenant.name", equalTo(academy))
                    .body("tenant.slug", equalTo(slug))
                    .body("tenant.defaultLocale", equalTo("es"))
                    .body("temporaryPassword", notNullValue());
            password = accepted.extract().path("temporaryPassword");
            tenant = accepted.extract().path("tenant.id");
            PasswordLeaks.assertNeverStoredOrLogged(tenant, password, logs);
        }
        accepted.body("request.tenantId", equalTo(tenant));
        assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(password);
        assertThat(CoreDb.count(tenant, """
                select count(*) from core.person p
                  join core.membership_role r on r.person_id = p.id and r.role = 'ADMIN'
                  join core.app_user u on u.id = p.user_id and u.keycloak_sub = ?
                 where p.email = ? and p.given_name = 'Lucía' and p.family_name = 'Pérez'""", sub, email))
                .isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.membership_role")).isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).contains("tenant.created", "tenant.request_accepted");
        assertThat(CoreDb.auditRow(tenant, "tenant.request_accepted")).containsEntry("targetId", tenant)
                .containsEntry("targetType", "tenant").containsEntry("actorSub", "platform-admin")
                .containsEntry("metadata", "{\"requesterRole\": \"COACH\", \"academyRequestId\": \"" + id + "\"}");

        Mail mail = onlyMailTo(email);
        assertThat(mail.getSubject()).isEqualTo("Tu academia ya está lista en Hoops Academy");
        assertThat(mail.getText()).contains(academy, email, "http://localhost:8080/login", "contraseña temporal")
                .doesNotContain(password);
        assertThat(mail.getHtml()).isNull();
    }

    @Test
    void anExistingLoginIsLinkedWithoutAPasswordAndTheMailSaysSo() {
        String academy = unique("Linked Club");
        String email = email("known");
        submitAnonymously(academy, email, "PARENT", "en");
        KeycloakStubs.existingUser(keycloak, email, UUID.randomUUID().toString());

        accept(requestId(academy), acceptBody(Slugs.unique("linked"))).statusCode(200)
                .body("$", not(hasKey("temporaryPassword")));

        assertThat(onlyMailTo(email).getText()).contains("already have a Hoops Academy login")
                .doesNotContain("temporary password");
    }

    @Test
    void aDecidedRequestCannotBeDecidedAgainAndAnUnknownOneIs404() {
        String academy = unique("Twice Club");
        submitAnonymously(academy, "en");
        String id = requestId(academy);
        accept(id, acceptBody(Slugs.unique("twice"))).statusCode(200);
        KeycloakStubs.installDefaults(keycloak);

        accept(id, acceptBody(Slugs.unique("twice"))).statusCode(409).body("code", equalTo("REQUEST_NOT_PENDING"));
        reject(id, "late").statusCode(409).body("code", equalTo("REQUEST_NOT_PENDING"));
        keycloak.verify(0, userCreated());
        accept(UUID.randomUUID().toString(), acceptBody(Slugs.unique("none"))).statusCode(404);
        reject(UUID.randomUUID().toString(), "x").statusCode(404);
    }

    @Test
    void aTakenSlugLeavesTheRequestPendingAndCreatesNothing() {
        String taken = Slugs.unique("taken");
        String other = unique("Other Club");
        submitAnonymously(other, "en");
        accept(requestId(other), acceptBody(taken)).statusCode(200);
        KeycloakStubs.installDefaults(keycloak);
        String academy = unique("Slug Clash");
        submitAnonymously(academy, "en");
        String id = requestId(academy);

        accept(id, acceptBody(taken)).statusCode(409).body("code", equalTo("SLUG_TAKEN"));

        keycloak.verify(0, userCreated());
        assertPending(id);
        accept(id, acceptBody(Slugs.unique("free"))).statusCode(200);
    }

    @Test
    void aKeycloakFailureLeavesTheRequestPendingAndNoAcademy() {
        String academy = unique("Down Club");
        submitAnonymously(academy, "en");
        String id = requestId(academy);
        KeycloakStubs.createUserFails(keycloak);

        accept(id, acceptBody(Slugs.unique("down"))).statusCode(502);

        assertPending(id);
        assertThat(CoreDb.countAsPlatform("select count(*) from core.tenant where name = ?", academy)).isZero();
        assertThat(mailbox.getTotalMessagesSent()).isZero();
    }

    @Test
    void anAcademyThatGotTheNameMeanwhileBlocksTheAcceptance() {
        String academy = unique("Race Club");
        submitAnonymously(academy, "en");
        String id = requestId(academy);
        academyNamed(academy.toUpperCase());

        accept(id, acceptBody(Slugs.unique("race"))).statusCode(409).body("code", equalTo("ACADEMY_NAME_TAKEN"));

        assertPending(id);
        keycloak.verify(0, userCreated());
    }

    @Test
    void anInvalidAcceptanceIsRejectedBeforeAnySideEffect() {
        String academy = unique("Invalid Accept");
        submitAnonymously(academy, "en");
        String id = requestId(academy);

        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).contentType(ContentType.JSON)
                .body(acceptBody("Bad Slug")).post(REQUESTS + "/" + id + ":accept").then().statusCode(400);
        accept(id, acceptBody(Slugs.unique("tz")).replace("Europe/Madrid", "Mars/Olympus")).statusCode(422)
                .body("code", equalTo("INVALID_TIMEZONE"));

        assertPending(id);
        keycloak.verify(0, userCreated());
    }

    // ------------------------------------------------------------------ reject

    @Test
    void rejectingRecordsTheDecisionAndEmailsTheReasonInTheRequestersLanguage() {
        String academy = unique("Rejected Club");
        String email = email("rej");
        submitAnonymously(academy, email, "ADMIN", "id");
        String id = requestId(academy);

        reject(id, "Bukan akademi basket.\nMaaf.").statusCode(200)
                .body("status", equalTo("REJECTED"))
                .body("reason", equalTo("Bukan akademi basket.\nMaaf."))
                .body("decidedBy", equalTo("platform-admin"))
                .body("notifiedAt", notNullValue())
                .body("tenantId", nullValue());

        Mail mail = onlyMailTo(email);
        assertThat(mail.getSubject()).isEqualTo("Permintaan akademimu di Hoops Academy");
        assertThat(mail.getText()).contains(academy, "Bukan akademi basket.\nMaaf.", "http://localhost:8080/");
        assertThat(CoreDb.countAsPlatform("select count(*) from core.tenant where name = ?", academy)).isZero();
    }

    @Test
    void aReasonIsRequiredAndBounded() {
        String academy = unique("Reason Club");
        submitAnonymously(academy, "en");
        String id = requestId(academy);

        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).contentType(ContentType.JSON)
                .body("{\"reason\":\" \"}")
                .post(REQUESTS + "/" + id + ":reject").then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).contentType(ContentType.JSON)
                .body("{\"reason\":\"" + "r".repeat(501) + "\"}").post(REQUESTS + "/" + id + ":reject").then()
                .statusCode(400);
        assertPending(id);
    }

    // ------------------------------------------------------------------ helpers

    private static String unique(String prefix) {
        return prefix + " " + UUID.randomUUID().toString().substring(0, 8);
    }

    private static String email(String prefix) {
        return prefix + "." + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
    }

    private static String body(String name, String email, String role, String academyName, String locale) {
        StringBuilder json = new StringBuilder("{");
        if (name != null) {
            json.append("\"name\":\"").append(name).append("\",");
        }
        return json.append("\"email\":\"").append(email).append("\",\"role\":\"").append(role)
                .append("\",\"academyName\":\"").append(academyName).append("\",\"locale\":\"").append(locale)
                .append("\"}").toString();
    }

    private static String acceptBody(String slug) {
        return """
                {"slug":"%s","timezone":"Europe/Madrid","defaultLocale":"es",
                 "firstAdmin":{"givenName":"Lucía","familyName":"Pérez"}}""".formatted(slug);
    }

    private static ValidatableResponse submit(String json) {
        return given().filter(Contract.CORE).contentType(ContentType.JSON).body(json).post(REQUESTS).then();
    }

    private static void submitAnonymously(String academy, String locale) {
        submitAnonymously(academy, UUID.randomUUID() + "@example.com", "ADMIN", locale);
    }

    private static void submitAnonymously(String academy, String email, String role, String locale) {
        submit(body("Lucía Pérez", email, role, academy, locale)).statusCode(202);
    }

    private static ValidatableResponse accept(String id, String json) {
        return given().filter(Contract.CORE).urlEncodingEnabled(false).contentType(ContentType.JSON).body(json)
                .post(REQUESTS + "/" + id + ":accept").then();
    }

    private static ValidatableResponse reject(String id, String reason) {
        return given().filter(Contract.CORE).urlEncodingEnabled(false).contentType(ContentType.JSON)
                .body("{\"reason\":\"" + reason.replace("\n", "\\n") + "\"}")
                .post(REQUESTS + "/" + id + ":reject").then();
    }

    private static String requestId(String academy) {
        return CoreDb.inTenant(null, c -> {
            try (var statement = c.prepareStatement(
                    "select id::text from core.academy_request where academy_name = ? order by requested_at desc")) {
                statement.setString(1, academy);
                try (var rs = statement.executeQuery()) {
                    assertThat(rs.next()).as("request for " + academy).isTrue();
                    return rs.getString(1);
                }
            }
        });
    }

    private static void assertPending(String id) {
        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where id = ?::uuid "
                + "and status = 'PENDING' and created_tenant_id is null and decided_by is null", id)).isEqualTo(1);
    }

    private static void academyNamed(String name) {
        String id = UUID.randomUUID().toString();
        CoreDb.tenant(id);
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set name = ? where id = ?::uuid", name, id));
    }

    private Mail onlyMailTo(String email) {
        List<Mail> mails = mailbox.getMailsSentTo(email);
        assertThat(mails).as("mails to the requester").hasSize(1);
        return mails.getFirst();
    }
}
