package com.hoopsacademy.core.testsupport;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.okJson;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathMatching;

import com.github.tomakehurst.wiremock.WireMockServer;

/** {@code /internal/usage/{tenantId}} of game (answers) and athlete (unavailable) plus the service-token endpoint. */
public final class UsageStubs {

    private static final String SERVICE_TOKEN = "/auth/realms/academy/protocol/openid-connect/token";

    private UsageStubs() {}

    static void installDefaults(WireMockServer server) {
        server.stubFor(post(urlEqualTo(SERVICE_TOKEN)).willReturn(okJson(
                "{\"access_token\":\"test-service-token\",\"token_type\":\"Bearer\",\"expires_in\":300}")));
        server.stubFor(get(urlPathMatching("/game/internal/usage/.+")).willReturn(okJson("""
                {"tenantId":"{{request.pathSegments.[3]}}","service":"game",
                 "collectedAt":"2026-11-01T10:00:00Z","counters":{"matches":3,"liveMatches":0}}
                """)));
        server.stubFor(get(urlPathMatching("/athlete/internal/usage/.+")).willReturn(aResponse().withStatus(503)));
    }
}
