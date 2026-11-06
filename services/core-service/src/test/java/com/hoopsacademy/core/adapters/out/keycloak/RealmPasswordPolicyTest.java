package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * The realm settings the temporary-password sign-in relies on (ADR-0024): the password policy the generator is built
 * for, brute-force protection on, no e-mail verification, e-mail as username. The policy's blocklist (ADR-0038) is
 * the file {@value #BLOCKLIST}, which compose mounts and the chart ships as a copy.
 */
class RealmPasswordPolicyTest {

    static final String BLOCKLIST = "infra/keycloak/password-blocklist/hoops-password-blocklist.txt";
    private static final String CHART_BLOCKLIST = "deploy/helm/hoops/charts/keycloak/files/hoops-password-blocklist.txt";
    private static final int MIN_LENGTH = 12;
    private static final int MAX_LENGTH = 128;

    private final JsonNode realm = read("infra/keycloak/realm-academy.json");

    @Test
    void thePasswordPolicyIsTheOneTheGeneratorMeetsAndBlocksCommonPasswords() {
        assertThat(realm.path("passwordPolicy").asText())
                .isEqualTo("length(" + MIN_LENGTH + ") and maxLength(" + MAX_LENGTH + ") and notUsername and notEmail"
                        + " and passwordBlacklist(" + Path.of(BLOCKLIST).getFileName() + ")");
    }

    @Test
    void theBlocklistHoldsAtLeastTheTop3000PasswordsThePolicyWouldOtherwiseAccept() throws IOException {
        // ASVS 5.0 6.2.4: shorter or longer entries would never be reached (the length rules reject them first)
        List<String> entries = Files.readAllLines(locate(BLOCKLIST), StandardCharsets.UTF_8);

        assertThat(entries).hasSizeGreaterThanOrEqualTo(3000).doesNotHaveDuplicates()
                .allSatisfy(entry -> assertThat(entry.length()).isBetween(MIN_LENGTH, MAX_LENGTH))
                .allSatisfy(entry -> assertThat(entry).as("Keycloak compares lower-cased").isLowerCase());
        assertThat(entries.stream().mapToInt(String::length).min().orElseThrow()).isEqualTo(MIN_LENGTH);
    }

    @Test
    void theChartShipsTheSameBlocklist() {
        assertThat(locate(CHART_BLOCKLIST)).hasSameBinaryContentAs(locate(BLOCKLIST));
    }

    @Test
    void bruteForceProtectionStaysOnAndNoEmailVerificationIsRequired() {
        assertThat(realm.path("bruteForceProtected").asBoolean()).isTrue();
        assertThat(realm.path("verifyEmail").asBoolean()).isFalse();
        assertThat(realm.path("registrationEmailAsUsername").asBoolean()).isTrue();
    }

    private static JsonNode read(String relative) {
        try {
            return new ObjectMapper().readTree(Files.readString(locate(relative))
                    .replaceAll("\\$\\{[A-Z_]+}", "placeholder"));
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    static Path locate(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            Path file = dir.resolve(relative);
            if (Files.exists(file)) {
                return file;
            }
        }
        throw new IllegalStateException(relative + " not found");
    }
}
