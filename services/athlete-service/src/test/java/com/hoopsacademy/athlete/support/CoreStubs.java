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

    /** core-service's own liveness endpoint (probed by the readiness indicator); delay in ms, 0 for none. */
    public CoreStubs coreLiveness(int status, int delayMillis) {
        wireMock.register(get(urlPathEqualTo("/q/health/live"))
                .willReturn(aResponse().withStatus(status).withFixedDelay(delayMillis)));
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

    /** A team roster with full player rows ({@code [id, displayName, birthDate, gender, status]}) and staff person ids. */
    public CoreStubs rosterOf(String tenant, String team, String teamName, List<String[]> players, List<String> staff) {
        return rosterOf(tenant, team, teamName, players, staff, null);
    }

    /** As above, with the last day of the team's season ({@code null} = not sent, as an older core). */
    public CoreStubs rosterOf(String tenant, String team, String teamName, List<String[]> players, List<String> staff,
            java.time.LocalDate seasonEndDate) {
        String rows = players.stream()
                .map(p -> "{\"playerId\":\"%s\",\"displayName\":\"%s\",\"birthDate\":\"%s\",\"gender\":\"%s\",\"status\":\"%s\"}"
                        .formatted(p[0], p[1], p[2], p[3], p[4]))
                .collect(Collectors.joining(","));
        String staffRows = staff.stream().map(id -> "{\"personId\":\"%s\",\"role\":\"COACH\"}".formatted(id))
                .collect(Collectors.joining(","));
        wireMock.register(get(urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        "{\"tenantId\":\"%s\",\"teamId\":\"%s\",\"seasonId\":\"%s\",\"teamName\":\"%s\",\"players\":[%s],\"staff\":[%s]%s}"
                                .formatted(tenant, team, UUID.randomUUID(), teamName, rows, staffRows,
                                        seasonEndDate == null ? "" : ",\"seasonEndDate\":\"" + seasonEndDate + "\""))));
        return this;
    }

    /** The players batch answers these full rows ({@code [id, displayName, birthDate, gender, status]}). */
    public CoreStubs playerBriefs(String tenant, List<String[]> players) {
        String rows = players.stream()
                .map(p -> "{\"id\":\"%s\",\"displayName\":\"%s\",\"birthDate\":\"%s\",\"gender\":\"%s\",\"status\":\"%s\"}"
                        .formatted(p[0], p[1], p[2], p[3], p[4]))
                .collect(Collectors.joining(","));
        wireMock.register(post(urlPathEqualTo("/internal/players:batch"))
                .withQueryParam("tenantId", equalTo(tenant))
                .willReturn(aResponse().withHeader("Content-Type", "application/json")
                        .withBody("{\"players\":[%s]}".formatted(rows))));
        return this;
    }

    /**
     * A full {@code AuthzContext} answer: person id, roles, staff teams, linked players, own player (or null), player
     * teams and zone ({@code null} = absent), tenant status.
     */
    public CoreStubs memberContext(String tenant, String sub, UUID personId, String status, String timezone,
            List<String> roles, List<UUID> staffTeams, List<UUID> linked, UUID ownPlayer, List<UUID> playerTeams) {
        return memberContext(tenant, sub, personId, status, timezone, roles, staffTeams, linked, ownPlayer, playerTeams,
                List.of());
    }

    /** As above, with the teams of ended seasons the member was staff of ({@code historicStaffTeamIds}, ADR-0042). */
    public CoreStubs memberContext(String tenant, String sub, UUID personId, String status, String timezone,
            List<String> roles, List<UUID> staffTeams, List<UUID> linked, UUID ownPlayer, List<UUID> playerTeams,
            List<UUID> historicStaffTeams) {
        wireMock.register(get(urlPathEqualTo("/internal/authz/" + tenant + "/" + sub))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        ("{\"sub\":\"%s\",\"personId\":\"%s\",\"tenantId\":\"%s\",\"tenantStatus\":\"%s\",\"roles\":%s,"
                                + "\"staffTeamIds\":%s,\"historicStaffTeamIds\":%s,\"linkedPlayerIds\":%s,"
                                + "\"ownPlayerId\":%s,\"playerTeamIds\":%s%s}")
                                .formatted(sub, personId, tenant, status, json(roles), json(strings(staffTeams)),
                                        json(strings(historicStaffTeams)),
                                        json(strings(linked)), ownPlayer == null ? "null" : "\"" + ownPlayer + "\"",
                                        json(strings(playerTeams)),
                                        timezone == null ? "" : ",\"timezone\":\"" + timezone + "\""))));
        return this;
    }

    private static List<String> strings(List<UUID> ids) {
        return ids.stream().map(UUID::toString).toList();
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

    /**
     * Players known to core with their own birth date and gender (each row {@code {id, birthDate, gender}}; a null
     * birth date or gender is sent as JSON null, which a real core never does but an incomplete record could).
     */
    public CoreStubs knownPlayerData(String tenant, String[]... rows) {
        String players = Arrays.stream(rows)
                .map(r -> "{\"id\":\"%s\",\"displayName\":\"Player %s\",\"birthDate\":%s,\"gender\":%s,\"status\":\"ACTIVE\"}"
                        .formatted(r[0], r[0].substring(r[0].length() - 4), r[1] == null ? "null" : "\"" + r[1] + "\"",
                                r[2] == null ? "null" : "\"" + r[2] + "\""))
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
