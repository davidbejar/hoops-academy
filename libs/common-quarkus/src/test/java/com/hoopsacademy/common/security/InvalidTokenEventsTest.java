package com.hoopsacademy.common.security;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import jakarta.inject.Inject;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.logging.Handler;
import java.util.logging.LogRecord;
import org.jboss.logmanager.Logger;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * ASVS 16.3.1 on the service side / ADR-0043: a bearer token that Quarkus OIDC refuses (expired, foreign audience,
 * bad signature, garbage) is one {@code invalid_token} event naming what failed, never the token or its claims.
 */
@QuarkusTest
@TestProfile(InvalidTokenEventsTest.RealTokens.class)
@WithTestResource(PostgresRlsResource.class)
@WithTestResource(LocalTokenIssuer.class)
class InvalidTokenEventsTest {

    private static final String WHOAMI = "/api/probe/whoami";
    private static final String SUBJECT = "sub-of-a-real-token";

    /** Own profile (own application start): bearer tokens are verified, as in production. */
    public static class RealTokens implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("hoops.security.require-sub", "true");
        }
    }

    LocalTokenIssuer.Tokens tokens;

    @Inject
    MeterRegistry registry;

    @Test
    void anExpiredTokenIsLoggedAsExpired() {
        assertRefused(tokens.expired(SUBJECT), "expired");
    }

    @Test
    void aTokenForAnotherAudienceIsLoggedAsAudience() {
        assertRefused(tokens.forAudience(SUBJECT, "another-service"), "audience");
    }

    @Test
    void aTokenSignedByAnotherKeyIsLoggedAsSignature() {
        assertRefused(tokens.signedByAnotherKey(SUBJECT), "signature");
    }

    @ParameterizedTest
    @ValueSource(strings = {"not-a-jwt", "eyJhbGciOiJub25lIn0.eyJzdWIiOiJ4In0."})
    void garbageIsLoggedAsInvalid(String token) {
        assertRefused(token, "invalid");
    }

    @Test
    void aValidTokenOfANonMemberIsNotAnInvalidToken() {
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().auth().oauth2(tokens.valid(SUBJECT)).header("X-Tenant-Id", AuthzDenialEventsTest.TENANT)
                    .get(WHOAMI).then().statusCode(404);

            assertThat(events.single())
                    .containsEntry("security.kind", "not_member")
                    .containsEntry("security.subject", SUBJECT);
        }
    }

    /** Quarkus OIDC's own warning quotes a refused token (header and claims, CWE-532); the library mutes it. */
    @Test
    void noOtherLogRecordQuotesARefusedToken() {
        String token = tokens.signedByAnotherKey(SUBJECT);
        List<String> records = new CopyOnWriteArrayList<>();
        Handler handler = new Handler() {
            @Override
            public void publish(LogRecord record) {
                records.add(record.getLoggerName() + " " + record.getMessage() + " " + Arrays.toString(record.getParameters()));
            }

            @Override
            public void flush() {}

            @Override
            public void close() {}
        };
        Logger root = Logger.getLogger("");
        root.addHandler(handler);
        try {
            given().auth().oauth2(token).header("X-Tenant-Id", AuthzDenialEventsTest.TENANT).get(WHOAMI).then()
                    .statusCode(401);
        } finally {
            root.removeHandler(handler);
        }

        String payload = token.split("\\.")[1];
        assertThat(records).noneMatch(line -> line.contains(payload));
    }

    private void assertRefused(String token, String reason) {
        double before = registry.counter("hoops.authz.denied", "kind", "invalid_token").count();
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().auth().oauth2(token).header("X-Tenant-Id", AuthzDenialEventsTest.TENANT).get(WHOAMI).then()
                    .statusCode(401);

            Map<String, String> event = events.single();
            assertThat(event)
                    .containsEntry("security.kind", "invalid_token")
                    .containsEntry("security.outcome", "401")
                    .containsEntry("security.subject", "-")
                    .containsEntry("security.reason", reason)
                    .containsEntry("security.resource", "GET " + WHOAMI);
            assertThat(String.join(" ", event.values())).doesNotContain(token).doesNotContain(SUBJECT);
        }
        assertThat(registry.counter("hoops.authz.denied", "kind", "invalid_token").count()).isEqualTo(before + 1);
    }
}
