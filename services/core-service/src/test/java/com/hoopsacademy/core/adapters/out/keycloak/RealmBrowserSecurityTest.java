package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Files;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.StreamSupport;
import org.junit.jupiter.api.Test;

/**
 * The realm's browser hardening (ADR-0038) without a container: the security headers Keycloak sends on its login and
 * account pages, and OTP offered to everyone but forced on nobody. The {@code @Tag("keycloak")} tests prove both on a
 * real Keycloak; the ZAP baseline proves the headers through nginx.
 */
class RealmBrowserSecurityTest {

    /** The Flutter dev server (compose only): the chart rewrites it to its public URL, which is {@code 'self'}. */
    private static final String DEV_SERVER = "http://localhost:5173";

    private final JsonNode realm = read();

    @Test
    void theContentSecurityPolicyDefinesEveryDirectiveWithoutWildcardsOrEval() {
        Map<String, List<String>> csp = directives(headers().path("contentSecurityPolicy").asText());

        assertThat(csp).containsOnlyKeys("default-src", "script-src", "style-src", "img-src", "font-src",
                "connect-src", "frame-src", "frame-ancestors", "form-action", "base-uri", "object-src");
        assertThat(csp.get("default-src")).containsExactly("'self'");
        // Keycloak 26 renders per-request inline scripts (session polling, import maps) and offers no nonce: the one
        // accepted ZAP finding on its pages
        assertThat(csp.get("script-src")).containsExactly("'self'", "'unsafe-inline'");
        assertThat(csp.get("style-src")).containsExactly("'self'", "'unsafe-inline'");
        assertThat(csp.get("img-src")).containsExactly("'self'", "data:"); // the OTP QR code is a data: image
        assertThat(csp.get("font-src")).containsExactly("'self'");
        assertThat(csp.get("connect-src")).containsExactly("'self'");
        assertThat(csp.get("frame-src")).containsExactly("'self'");
        assertThat(csp.get("frame-ancestors")).containsExactly("'self'");
        // Chrome applies form-action to the redirect after the login POST: the app's origins only
        assertThat(csp.get("form-action")).containsExactly("'self'", DEV_SERVER);
        assertThat(csp.get("base-uri")).containsExactly("'self'");
        assertThat(csp.get("object-src")).containsExactly("'none'");
        assertThat(csp.values()).flatMap(sources -> sources).doesNotContain("*", "'unsafe-eval'", "http:", "https:");
    }

    @Test
    void theOtherSecurityHeadersAreExplicit() {
        JsonNode headers = headers();

        assertThat(headers.path("xFrameOptions").asText()).isEqualTo("SAMEORIGIN");
        assertThat(headers.path("xContentTypeOptions").asText()).isEqualTo("nosniff");
        assertThat(headers.path("referrerPolicy").asText()).isEqualTo("no-referrer");
        assertThat(headers.path("strictTransportSecurity").asText()).isEqualTo("max-age=31536000; includeSubDomains");
        assertThat(headers.path("xRobotsTag").asText()).isEqualTo("none");
        assertThat(headers.path("contentSecurityPolicyReportOnly").asText()).isEmpty();
    }

    @Test
    void otpIsATimeBasedCodeAnyAuthenticatorAppCanRead() {
        assertThat(realm.path("otpPolicyType").asText()).isEqualTo("totp");
        assertThat(realm.path("otpPolicyAlgorithm").asText()).isEqualTo("HmacSHA1");
        assertThat(realm.path("otpPolicyDigits").asInt()).isEqualTo(6);
        assertThat(realm.path("otpPolicyPeriod").asInt()).isEqualTo(30);
        assertThat(realm.path("otpPolicyLookAheadWindow").asInt()).isEqualTo(1);
        assertThat(realm.path("otpPolicyCodeReusable").asBoolean(true)).isFalse();
    }

    @Test
    void otpIsOfferedButForcedOnNobody() {
        // Keycloak's built-in browser flow asks for the OTP only when the user configured one (conditional 2FA), and
        // its built-in CONFIGURE_TOTP action is enabled but no default action. A realm file that listed requiredActions
        // or authenticationFlows would replace those built-ins.
        assertThat(realm.has("requiredActions")).isFalse();
        assertThat(realm.has("authenticationFlows")).isFalse();
        assertThat(realm.path("browserFlow").asText("browser")).isEqualTo("browser");
        assertThat(StreamSupport.stream(realm.path("users").spliterator(), false)
                .flatMap(user -> StreamSupport.stream(user.path("requiredActions").spliterator(), false))
                .map(JsonNode::asText)).doesNotContain("CONFIGURE_TOTP");
    }

    private JsonNode headers() {
        return realm.path("browserSecurityHeaders");
    }

    private static Map<String, List<String>> directives(String policy) {
        Map<String, List<String>> out = new LinkedHashMap<>();
        for (String directive : policy.split(";")) {
            List<String> parts = Arrays.stream(directive.trim().split("\\s+")).filter(p -> !p.isEmpty()).toList();
            if (!parts.isEmpty()) {
                assertThat(out).as("directive %s once", parts.get(0)).doesNotContainKey(parts.get(0));
                out.put(parts.get(0), parts.subList(1, parts.size()));
            }
        }
        return out;
    }

    private static JsonNode read() {
        try {
            return new ObjectMapper().readTree(Files.readString(
                    RealmPasswordPolicyTest.locate("infra/keycloak/realm-academy.json"))
                    .replaceAll("\\$\\{[A-Z_]+}", "placeholder"));
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }
}
