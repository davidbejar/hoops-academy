package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * The realm's token settings (ADR-0034) without a container: refresh tokens rotate with reuse detection (F-08) while
 * the SSO session lengths stay as they were, and each client's access tokens carry exactly the audiences of the
 * services it calls (F-14): the web client all three, a service only the services it calls. The services verify their
 * own audience ({@code quarkus.oidc.token.audience}); the {@code @Tag("keycloak")} tests prove it with real tokens.
 */
class RealmTokenPolicyTest {

    private final JsonNode realm = read("infra/keycloak/realm-academy.json");

    @Test
    void refreshTokensRotateAndAUsedOneIsNeverAcceptedAgain() {
        assertThat(realm.path("revokeRefreshToken").asBoolean()).isTrue();
        assertThat(realm.path("refreshTokenMaxReuse").isInt()).isTrue();
        assertThat(realm.path("refreshTokenMaxReuse").asInt()).isZero();
    }

    @Test
    void theSsoSessionLengthsAreUnchanged() {
        assertThat(realm.path("ssoSessionIdleTimeout").asInt()).isEqualTo(14_400);
        assertThat(realm.path("ssoSessionMaxLifespan").asInt()).isEqualTo(43_200);
        assertThat(realm.path("accessTokenLifespan").asInt()).isEqualTo(300);
    }

    @ParameterizedTest
    @CsvSource({
        "web, core-service game-service athlete-service",
        "core-service, game-service athlete-service",
        "game-service, core-service",
        "athlete-service, core-service"})
    void eachClientsTokensCarryTheAudiencesOfTheServicesItCalls(String clientId, String audiences) {
        assertThat(audiencesOf(clientId)).containsExactlyInAnyOrder(audiences.split(" "));
    }

    @Test
    void noRealmLevelClientScopesReplaceKeycloaksBuiltInOnes() {
        // a realm import that lists clientScopes gets none of the built-in ones (basic, profile, roles, ...)
        assertThat(realm.has("clientScopes")).isFalse();
    }

    private List<String> audiencesOf(String clientId) {
        List<String> out = new ArrayList<>();
        for (JsonNode client : realm.path("clients")) {
            if (clientId.equals(client.path("clientId").asText())) {
                for (JsonNode mapper : client.path("protocolMappers")) {
                    if ("oidc-audience-mapper".equals(mapper.path("protocolMapper").asText())) {
                        JsonNode config = mapper.path("config");
                        assertThat(config.path("access.token.claim").asText()).as(mapper.toString()).isEqualTo("true");
                        assertThat(config.path("id.token.claim").asText()).as(mapper.toString()).isEqualTo("false");
                        out.add(config.path("included.client.audience").asText());
                    }
                }
                return out;
            }
        }
        throw new IllegalStateException("realm has no client " + clientId);
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
