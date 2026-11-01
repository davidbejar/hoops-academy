package com.hoopsacademy.athlete.support;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.core.WireMockConfiguration;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.util.Map;

/**
 * Stands in for core-service and Keycloak's token endpoint. Tests get at the server through {@link CoreStubs},
 * which talks to it over HTTP using the {@code wiremock.port} config value (the resource and the tests may be
 * loaded by different class loaders, so no static state is shared).
 */
public class CoreMockResource implements QuarkusTestResourceLifecycleManager {

    private WireMockServer server;

    @Override
    public Map<String, String> start() {
        server = new WireMockServer(WireMockConfiguration.options().dynamicPort());
        server.start();
        String base = "http://localhost:" + server.port();
        return Map.of(
                "wiremock.port", Integer.toString(server.port()),
                "hoops.core.url", base,
                "quarkus.oidc-client.auth-server-url", base);
    }

    @Override
    public void stop() {
        if (server != null) {
            server.stop();
        }
    }
}
