package com.hoopsacademy.core.adapters.out.mail;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** No mail server answers: the decision stands, {@code notifiedAt} stays empty (ADR-0044). */
@QuarkusTest
@TestProfile(AcademyRequestMailFailureTest.NoMailServer.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class AcademyRequestMailFailureTest {

    /** A real SMTP client against a port nobody listens on. */
    public static class NoMailServer implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("quarkus.mailer.mock", "false", "quarkus.mailer.host", "127.0.0.1",
                    "quarkus.mailer.port", "1");
        }
    }

    @Test
    void anUnreachableMailServerLeavesTheRejectionStandingAndLogsNoAddress() {
        String academy = "Mail Down " + UUID.randomUUID().toString().substring(0, 8);
        String email = "down." + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        given().filter(Contract.CORE).contentType(ContentType.JSON)
                .body("{\"email\":\"" + email + "\",\"role\":\"ADMIN\",\"academyName\":\"" + academy + "\"}")
                .post("/platform/academy-requests").then().statusCode(202);
        String id = CoreDb.inTenant(null, c -> {
            try (var statement = c.prepareStatement("select id::text from core.academy_request where academy_name = ?")) {
                statement.setString(1, academy);
                try (var rs = statement.executeQuery()) {
                    rs.next();
                    return rs.getString(1);
                }
            }
        });

        try (LogCapture logs = LogCapture.start()) {
            given().filter(Contract.CORE).urlEncodingEnabled(false).contentType(ContentType.JSON)
                    .body("{\"reason\":\"Not now\"}").post("/platform/academy-requests/" + id + ":reject")
                    .then().statusCode(200).body("status", equalTo("REJECTED")).body("notifiedAt", nullValue());

            assertThat(logs.containing("not sent")).isNotEmpty();
            assertThat(logs.containing(email)).as("no address in the log").isEmpty();
        }
        assertThat(CoreDb.countAsPlatform("select count(*) from core.academy_request where id = ?::uuid "
                + "and status = 'REJECTED' and notified_at is null", id)).isEqualTo(1);
    }
}
