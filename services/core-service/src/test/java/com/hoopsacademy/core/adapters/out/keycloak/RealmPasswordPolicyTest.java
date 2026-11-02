package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

/**
 * The realm settings the temporary-password sign-in relies on (ADR-0024): the password policy the generator is built
 * for, brute-force protection on, no e-mail verification, e-mail as username.
 */
class RealmPasswordPolicyTest {

    private final JsonNode realm = read("infra/keycloak/realm-academy.json");

    @Test
    void thePasswordPolicyIsTheOneTheGeneratorMeets() {
        assertThat(realm.path("passwordPolicy").asText())
                .isEqualTo("length(12) and maxLength(128) and notUsername and notEmail");
    }

    @Test
    void bruteForceProtectionStaysOnAndNoEmailVerificationIsRequired() {
        assertThat(realm.path("bruteForceProtected").asBoolean()).isTrue();
        assertThat(realm.path("verifyEmail").asBoolean()).isFalse();
        assertThat(realm.path("registrationEmailAsUsername").asBoolean()).isTrue();
    }

    private static JsonNode read(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            Path file = dir.resolve(relative);
            if (Files.exists(file)) {
                try {
                    return new ObjectMapper().readTree(Files.readString(file)
                            .replaceAll("\\$\\{[A-Z_]+}", "placeholder"));
                } catch (IOException e) {
                    throw new IllegalStateException(e);
                }
            }
        }
        throw new IllegalStateException(relative + " not found");
    }
}
