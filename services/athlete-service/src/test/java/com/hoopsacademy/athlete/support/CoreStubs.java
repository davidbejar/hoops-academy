package com.hoopsacademy.athlete.support;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;

import com.github.tomakehurst.wiremock.client.WireMock;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.ConfigProvider;

/** Test-side handle on the WireMock "core-service": stubs for the three internal endpoints the adapter calls. */
public final class CoreStubs {

    private final WireMock wireMock;

    public CoreStubs() {
        int port = ConfigProvider.getConfig().getValue("wiremock.port", Integer.class);
        wireMock = new WireMock("localhost", port);
    }

    /** Clears all stubs and journal, then re-adds the token endpoint (client credentials). */
    public CoreStubs reset() {
        wireMock.resetMappings();
        wireMock.resetRequests();
        wireMock.register(post(urlPathEqualTo("/token")).willReturn(aResponse()
                .withHeader("Content-Type", "application/json")
                .withBody("{\"access_token\":\"athlete-service-token\",\"expires_in\":300,\"token_type\":\"Bearer\"}")));
        return this;
    }

    public CoreStubs roster(String tenant, String team, String... playerIds) {
        String players = Arrays.stream(playerIds)
                .map(id -> "{\"playerId\":\"%s\",\"displayName\":\"Player %s\",\"birthDate\":\"2012-05-01\",\"gender\":\"MALE\",\"status\":\"ACTIVE\"}"
                        .formatted(id, id.substring(id.length() - 4)))
                .collect(Collectors.joining(","));
        wireMock.register(get(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        "{\"tenantId\":\"%s\",\"teamId\":\"%s\",\"seasonId\":\"%s\",\"teamName\":\"U12\",\"players\":[%s],\"staff\":[]}"
                                .formatted(tenant, team, UUID.randomUUID(), players))));
        return this;
    }

    public CoreStubs rosterNotFound(String tenant, String team) {
        wireMock.register(get(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withStatus(404).withHeader("Content-Type", "application/problem+json")
                        .withBody("{\"type\":\"about:blank\",\"title\":\"Not Found\",\"status\":404}")));
        return this;
    }

    public CoreStubs rosterDelayed(String tenant, String team, int millis) {
        wireMock.register(get(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withFixedDelay(millis).withHeader("Content-Type", "application/json")
                        .withBody("{\"tenantId\":\"%s\",\"teamId\":\"%s\",\"seasonId\":\"%s\",\"teamName\":\"U12\",\"players\":[],\"staff\":[]}"
                                .formatted(tenant, team, UUID.randomUUID()))));
        return this;
    }

    public CoreStubs rosterFails(String tenant, String team, int status) {
        wireMock.register(get(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withStatus(status)));
        return this;
    }

    /** Every id given is "known" to core (answers the batch with a brief for each requested id). */
    public CoreStubs knownPlayers(String tenant, String... playerIds) {
        String players = Arrays.stream(playerIds)
                .map(id -> "{\"id\":\"%s\",\"displayName\":\"Player %s\",\"birthDate\":\"2012-05-01\",\"gender\":\"FEMALE\",\"status\":\"ACTIVE\"}"
                        .formatted(id, id.substring(id.length() - 4)))
                .collect(Collectors.joining(","));
        wireMock.register(post(urlPathEqualTo("/internal/players:batch"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withHeader("Content-Type", "application/json")
                        .withBody("{\"players\":[%s]}".formatted(players))));
        return this;
    }

    public CoreStubs member(String tenant, String sub, String status, String timezone, String rolesJson,
            String staffTeamsJson, String linkedJson, String ownPlayerJson) {
        wireMock.register(get(urlPathEqualTo("/internal/authz/" + tenant + "/" + sub))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        ("{\"sub\":\"%s\",\"personId\":\"%s\",\"tenantId\":\"%s\",\"tenantStatus\":\"%s\",\"roles\":%s,"
                                + "\"staffTeamIds\":%s,\"linkedPlayerIds\":%s,\"ownPlayerId\":%s%s}")
                                .formatted(sub, UUID.nameUUIDFromBytes(sub.getBytes()), tenant, status, rolesJson,
                                        staffTeamsJson, linkedJson, ownPlayerJson,
                                        timezone == null ? "" : ",\"timezone\":\"" + timezone + "\""))));
        return this;
    }

    public CoreStubs notAMember(String tenant, String sub) {
        wireMock.register(get(urlPathEqualTo("/internal/authz/" + tenant + "/" + sub))
                .willReturn(aResponse().withStatus(404).withHeader("Content-Type", "application/problem+json")
                        .withBody("{\"type\":\"about:blank\",\"title\":\"Not Found\",\"status\":404}")));
        return this;
    }

    public int rosterCalls(String team) {
        return wireMock.find(getRequestedFor(urlPathEqualTo("/internal/teams/" + team + "/roster"))).size();
    }

    public int batchCalls() {
        return wireMock.find(postRequestedFor(urlPathEqualTo("/internal/players:batch"))).size();
    }

    public int authzCalls(String tenant, String sub) {
        return wireMock.find(getRequestedFor(urlPathEqualTo("/internal/authz/" + tenant + "/" + sub))).size();
    }

    public int tokenCalls() {
        return wireMock.find(postRequestedFor(urlPathEqualTo("/token"))).size();
    }

    public boolean sentBearer(String team, String token) {
        return !wireMock.find(getRequestedFor(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withHeader("Authorization", equalTo("Bearer " + token))).isEmpty();
    }

    /** JSON array of UUID strings, for the {@code member} stub. */
    public static String json(List<String> ids) {
        return ids.stream().map(s -> "\"" + s + "\"").collect(Collectors.joining(",", "[", "]"));
    }
}
