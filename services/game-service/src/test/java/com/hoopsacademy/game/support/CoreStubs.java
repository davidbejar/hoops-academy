package com.hoopsacademy.game.support;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;

import com.github.tomakehurst.wiremock.WireMockServer;
import java.util.List;
import java.util.stream.Collectors;

/** Canned core-service answers (shapes from libs/contracts/openapi/core.yaml). */
public final class CoreStubs {

    public static final String SERVICE_TOKEN = "svc-token";

    private CoreStubs() {}

    public static void tokenEndpoint(WireMockServer wm) {
        wm.stubFor(post(urlPathEqualTo("/realms/academy/protocol/openid-connect/token"))
                .willReturn(aResponse().withHeader("Content-Type", "application/json")
                        .withBody("{\"access_token\":\"" + SERVICE_TOKEN + "\",\"token_type\":\"Bearer\",\"expires_in\":3600}")));
    }

    /** Clears stubs and journal, then re-registers the token endpoint. */
    public static void reset(WireMockServer wm) {
        wm.resetAll();
        tokenEndpoint(wm);
    }

    /** @param players each {"id", "name", "jersey"} (jersey may be null) */
    public static void teamRoster(WireMockServer wm, String tenant, String team, String season, String... players) {
        String body = String.join(",", players);
        wm.stubFor(get(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant))
                .withHeader("Authorization", equalTo("Bearer " + SERVICE_TOKEN))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        "{\"tenantId\":\"" + tenant + "\",\"teamId\":\"" + team + "\",\"seasonId\":\"" + season
                                + "\",\"teamName\":\"U14\",\"players\":[" + body + "],\"staff\":[]}")));
    }

    /** One roster player as JSON. */
    public static String player(String id, String name, String jersey) {
        return "{\"playerId\":\"" + id + "\",\"displayName\":\"" + name + "\",\"jerseyNumber\":"
                + (jersey == null ? "null" : "\"" + jersey + "\"")
                + ",\"birthDate\":\"2012-05-01\",\"gender\":\"MALE\",\"status\":\"ACTIVE\"}";
    }


    public static void authz(WireMockServer wm, String tenant, String sub, String tenantStatus, List<String> roles,
            List<String> staffTeams) {
        wm.stubFor(get(urlPathEqualTo("/internal/authz/" + tenant + "/" + sub))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        "{\"sub\":\"" + sub + "\",\"personId\":\"00000000-0000-4000-8000-0000000000aa\",\"tenantId\":\""
                                + tenant + "\",\"tenantStatus\":\"" + tenantStatus + "\",\"roles\":"
                                + quoted(roles) + ",\"staffTeamIds\":" + quoted(staffTeams) + ",\"linkedPlayerIds\":[]}")));
    }

    private static String quoted(List<String> values) {
        return values.stream().map(v -> "\"" + v + "\"").collect(Collectors.joining(",", "[", "]"));
    }
}
