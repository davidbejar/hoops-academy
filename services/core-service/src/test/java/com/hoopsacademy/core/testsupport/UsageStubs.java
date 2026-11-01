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

    /** Both peers answer with their documented counters. */
    public static void bothAnswer(WireMockServer server) {
        server.stubFor(get(urlPathMatching("/athlete/internal/usage/.+")).willReturn(okJson("""
                {"tenantId":"{{request.pathSegments.[3]}}","service":"athlete",
                 "collectedAt":"2026-11-01T10:00:00Z","lastActivityAt":"2026-10-31T18:00:00Z",
                 "counters":{"trainingSessions":12,"attendanceRecords":150,"injuries":1}}
                """)));
    }

    public static void down(WireMockServer server, String service) {
        server.stubFor(get(urlPathMatching("/" + service + "/internal/usage/.+")).willReturn(aResponse().withStatus(503)));
    }

    public static void unreachable(WireMockServer server, String service) {
        server.stubFor(get(urlPathMatching("/" + service + "/internal/usage/.+")).willReturn(aResponse()
                .withFault(com.github.tomakehurst.wiremock.http.Fault.CONNECTION_RESET_BY_PEER)));
    }

    /** Answers only after {@code millis}, longer than the 2 s client timeout. */
    public static void slow(WireMockServer server, String service, int millis) {
        server.stubFor(get(urlPathMatching("/" + service + "/internal/usage/.+")).willReturn(okJson(
                "{\"tenantId\":\"{{request.pathSegments.[3]}}\",\"service\":\"" + service
                        + "\",\"collectedAt\":\"2026-11-01T10:00:00Z\",\"counters\":{}}").withFixedDelay(millis)));
    }

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
