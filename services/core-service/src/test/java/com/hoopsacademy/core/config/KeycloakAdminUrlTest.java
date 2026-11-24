package com.hoopsacademy.core.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.ShippedConfig;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * core's Keycloak Admin API client reads its base from one variable, KEYCLOAK_ADMIN_URL (ADR-0071), whose default is
 * where {@code just up} serves Keycloak; the realm itself is OIDC_AUTH_SERVER_URL (the library's key).
 */
class KeycloakAdminUrlTest {

    private static final String KEY = "quarkus.keycloak.admin-client.server-url";

    @Test
    void defaultsToTheComposeKeycloak() {
        assertThat(ShippedConfig.load("prod", Map.of()).value(KEY)).contains("http://localhost:8080/auth");
    }

    @Test
    void followsKeycloakAdminUrlAndNothingElse() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of(
                "KEYCLOAK_ADMIN_URL", "http://keycloak:8080/auth",
                "KEYCLOAK_URL", "http://retired.example/auth"));

        assertThat(prod.value(KEY)).contains("http://keycloak:8080/auth");
    }
}
