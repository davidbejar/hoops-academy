package com.hoopsacademy.game.support;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.TeamRoster;
import java.util.Collection;
import java.util.UUID;

/**
 * Makes the WireMock core answer {@code /internal} exactly what a port contract case expects (core applies the
 * roster rules itself), so the same case runs against the REST adapter and against the replica.
 */
public final class CoreAnswers {

    private static final ObjectMapper JSON = new ObjectMapper();

    private CoreAnswers() {}

    public static void teamRoster(WireMockServer core, TenantId tenant, TeamRoster roster) {
        ObjectNode body = JSON.createObjectNode().put("tenantId", tenant.toString())
                .put("teamId", roster.teamId().value().toString()).put("seasonId", roster.seasonId().value().toString())
                .put("teamName", roster.teamName())
                .put("seasonEndDate", roster.seasonEndDate() == null ? null : roster.seasonEndDate().toString());
        ArrayNode players = body.putArray("players");
        roster.players().forEach(p -> players.addObject().put("playerId", p.playerId().value().toString())
                .put("displayName", p.displayName()).put("jerseyNumber", p.jerseyNumber())
                .put("birthDate", "2012-05-01").put("gender", "FEMALE").put("status", "ACTIVE"));
        body.putArray("staff");
        core.stubFor(get(urlPathEqualTo("/internal/teams/" + roster.teamId().value() + "/roster"))
                .withQueryParam("tenantId", equalTo(tenant.toString())).willReturn(json(body)));
    }

    public static void teamNotFound(WireMockServer core, UUID team) {
        core.stubFor(get(urlPathEqualTo("/internal/teams/" + team + "/roster")).willReturn(aResponse().withStatus(404)));
    }

    public static void players(WireMockServer core, TenantId tenant, Collection<PlayerBrief> players) {
        ObjectNode body = JSON.createObjectNode();
        ArrayNode list = body.putArray("players");
        players.forEach(p -> list.addObject().put("id", p.playerId().value().toString())
                .put("displayName", p.displayName()).put("birthDate", "2012-05-01").put("gender", "FEMALE")
                .put("status", "ACTIVE"));
        core.stubFor(post(urlPathEqualTo("/internal/players:batch")).withQueryParam("tenantId", equalTo(tenant.toString()))
                .willReturn(json(body)));
    }

    public static void playersNotFound(WireMockServer core) {
        core.stubFor(post(urlPathEqualTo("/internal/players:batch")).willReturn(aResponse().withStatus(404)));
    }

    /** @param tenantStatus what core reports besides the context (ACTIVE, SUSPENDED, WITHDRAWN) */
    public static void member(WireMockServer core, AuthzContext context, String tenantStatus) {
        ObjectNode body = JSON.createObjectNode().put("sub", context.subject())
                .put("personId", context.personId().toString()).put("tenantId", context.tenantId().toString())
                .put("tenantStatus", tenantStatus);
        ArrayNode roles = body.putArray("roles");
        context.roles().forEach(role -> roles.add(role.name()));
        ArrayNode staff = body.putArray("staffTeamIds");
        context.staffTeamIds().forEach(id -> staff.add(id.toString()));
        ArrayNode historic = body.putArray("historicStaffTeamIds");
        context.historicStaffTeamIds().forEach(id -> historic.add(id.toString()));
        ArrayNode linked = body.putArray("linkedPlayerIds");
        context.linkedPlayerIds().forEach(id -> linked.add(id.toString()));
        body.put("ownPlayerId", context.ownPlayerId().map(UUID::toString).orElse(null));
        ArrayNode playerTeams = body.putArray("playerTeamIds");
        context.playerTeamIds().forEach(id -> playerTeams.add(id.toString()));
        body.put("timezone", context.timezone().map(Object::toString).orElse(null));
        core.stubFor(get(urlPathEqualTo("/internal/authz/" + context.tenantId() + "/" + context.subject()))
                .willReturn(json(body)));
    }

    public static void notAMember(WireMockServer core, TenantId tenant, String subject) {
        core.stubFor(get(urlPathEqualTo("/internal/authz/" + tenant + "/" + subject)).willReturn(aResponse().withStatus(404)));
    }

    private static com.github.tomakehurst.wiremock.client.ResponseDefinitionBuilder json(ObjectNode body) {
        return aResponse().withHeader("Content-Type", "application/json").withBody(body.toString());
    }
}
