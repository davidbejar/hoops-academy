package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * The realm's event settings (ADR-0043) without a container: user events stored for 30 days and logged by the
 * {@code jboss-logging} listener, every authentication operation of ASVS 16.3.1 in the stored list, admin events on
 * without their representation. {@code RealmSecurityEventsKeycloakTest} proves the effect on a real Keycloak.
 */
class RealmSecurityEventsPolicyTest {

    private static final long THIRTY_DAYS = Duration.ofDays(30).toSeconds();

    private final JsonNode realm = read("infra/keycloak/realm-academy.json");

    @Test
    void userEventsAreStoredForThirtyDaysAndLogged() {
        assertThat(realm.path("eventsEnabled").asBoolean()).isTrue();
        assertThat(realm.path("eventsExpiration").asLong()).isEqualTo(THIRTY_DAYS);
        assertThat(texts(realm.path("eventsListeners"))).containsExactly("jboss-logging");
    }

    @Test
    void everyAuthenticationOperationIsAStoredEventType() {
        assertThat(texts(realm.path("enabledEventTypes"))).doesNotHaveDuplicates().contains(
                "LOGIN", "LOGIN_ERROR", "LOGOUT", "LOGOUT_ERROR", "CODE_TO_TOKEN_ERROR", "REFRESH_TOKEN_ERROR",
                "CLIENT_LOGIN_ERROR", "UPDATE_PASSWORD", "UPDATE_PASSWORD_ERROR", "UPDATE_TOTP", "REMOVE_TOTP",
                "UPDATE_CREDENTIAL", "REMOVE_CREDENTIAL", "RESET_PASSWORD", "SEND_RESET_PASSWORD",
                "USER_DISABLED_BY_TEMPORARY_LOCKOUT", "USER_DISABLED_BY_PERMANENT_LOCKOUT");
    }

    @Test
    void adminEventsAreOnWithoutTheirRepresentationAndExpire() {
        assertThat(realm.path("adminEventsEnabled").asBoolean()).isTrue();
        assertThat(realm.path("adminEventsDetailsEnabled").asBoolean()).isFalse();
        assertThat(realm.path("attributes").path("adminEventsExpiration").asText()).isEqualTo(Long.toString(THIRTY_DAYS));
    }

    private static List<String> texts(JsonNode array) {
        List<String> out = new ArrayList<>();
        array.forEach(node -> out.add(node.asText()));
        return out;
    }

    private static JsonNode read(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            Path file = dir.resolve(relative);
            if (Files.exists(file)) {
                try {
                    return new ObjectMapper().readTree(Files.readString(file).replaceAll("\\$\\{[A-Z_]+}", "placeholder"));
                } catch (IOException e) {
                    throw new IllegalStateException(e);
                }
            }
        }
        throw new IllegalStateException(relative + " not found");
    }
}
