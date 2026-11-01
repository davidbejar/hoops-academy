package com.hoopsacademy.core.testsupport;

import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.options;

import com.github.tomakehurst.wiremock.WireMockServer;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.util.Map;

/**
 * One WireMock server standing in for every HTTP collaborator of core-service in tests: the Keycloak token endpoint
 * and Admin API (paths as served under {@code /auth}), and the {@code /internal/usage} endpoints of game and athlete
 * (under {@code /game} and {@code /athlete}). Default stubs are installed by {@link KeycloakStubs#installDefaults}.
 */
public class WireMockResource implements QuarkusTestResourceLifecycleManager {

    private WireMockServer server;

    @Override
    public Map<String, String> start() {
        server = new WireMockServer(options().dynamicPort().globalTemplating(true));
        server.start();
        KeycloakStubs.installDefaults(server);
        String base = server.baseUrl();
        return Map.of(
                "quarkus.keycloak.admin-client.server-url", base + "/auth",
                "quarkus.oidc-client.auth-server-url", base + "/auth/realms/academy",
                "quarkus.rest-client.game-usage.url", base + "/game",
                "quarkus.rest-client.athlete-usage.url", base + "/athlete");
    }

    @Override
    public void inject(TestInjector testInjector) {
        testInjector.injectIntoFields(server,
                new TestInjector.AnnotatedAndMatchesType(InjectWireMock.class, WireMockServer.class));
    }

    @Override
    public void stop() {
        if (server != null) {
            server.stop();
        }
    }
}
