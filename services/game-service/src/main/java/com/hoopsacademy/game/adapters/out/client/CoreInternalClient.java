package com.hoopsacademy.game.adapters.out.client;

import com.hoopsacademy.common.client.ServiceTokenClientFilter;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.UUID;
import org.eclipse.microprofile.rest.client.annotation.RegisterProvider;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

/**
 * core-service {@code /internal/**} (libs/contracts/openapi/core.yaml). Calls carry the tenant explicitly (path or
 * query), never an X-Tenant-Id header. Base URL and timeouts: {@code quarkus.rest-client.core.*}.
 */
@RegisterRestClient(configKey = "core")
@RegisterProvider(ServiceTokenClientFilter.class)
@Path("/internal")
@Produces(MediaType.APPLICATION_JSON)
interface CoreInternalClient {

    @GET
    @Path("/authz/{tenantId}/{sub}")
    AuthzDto authz(@PathParam("tenantId") String tenantId, @PathParam("sub") String sub);

    @GET
    @Path("/teams/{teamId}/roster")
    TeamRosterDto teamRoster(@PathParam("teamId") UUID teamId, @QueryParam("tenantId") String tenantId);

    @POST
    @Path("/players:batch")
    @Consumes(MediaType.APPLICATION_JSON)
    PlayerBatchDto players(@QueryParam("tenantId") String tenantId, PlayerBatchRequestDto request);

    record AuthzDto(
            String sub, UUID personId, UUID tenantId, String tenantStatus, List<String> roles, List<UUID> staffTeamIds,
            List<UUID> linkedPlayerIds, UUID ownPlayerId) {}

    record TeamRosterDto(UUID tenantId, UUID teamId, UUID seasonId, String teamName, List<RosterPlayerDto> players) {}

    record RosterPlayerDto(UUID playerId, String displayName, String jerseyNumber, String status) {}

    record PlayerBatchRequestDto(List<UUID> playerIds) {}

    record PlayerBatchDto(List<PlayerBriefDto> players) {}

    record PlayerBriefDto(UUID id, String displayName) {}
}
