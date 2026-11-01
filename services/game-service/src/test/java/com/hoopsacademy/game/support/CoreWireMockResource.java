package com.hoopsacademy.game.support;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.core.WireMockConfiguration;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.util.Map;

/**
 * WireMock standing in for core-service {@code /internal/**} AND for the Keycloak token endpoint, so the real
 * {@code ServiceTokenClientFilter} runs end to end. Points {@code hoops.core.url} and the oidc-client at it.
 */
public class CoreWireMockResource implements QuarkusTestResourceLifecycleManager {

    private WireMockServer server;

    @Override
    public Map<String, String> start() {
        server = new WireMockServer(WireMockConfiguration.options().dynamicPort());
        server.start();
        CoreStubs.tokenEndpoint(server);
        String base = "http://localhost:" + server.port();
        return Map.of(
                "hoops.core.url", base,
                "quarkus.oidc-client.auth-server-url", base + "/realms/academy");
    }

    @Override
    public void stop() {
        if (server != null) {
            server.stop();
        }
    }

    @Override
    public void inject(TestInjector testInjector) {
        testInjector.injectIntoFields(server,
                new TestInjector.AnnotatedAndMatchesType(InjectCoreWireMock.class, WireMockServer.class));
    }
}
