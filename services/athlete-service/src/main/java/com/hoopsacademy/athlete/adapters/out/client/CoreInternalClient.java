package com.hoopsacademy.athlete.adapters.out.client;

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

/** core-service {@code /internal/**} (libs/contracts/openapi/core.yaml); authenticated with a client-credentials token. */
@RegisterRestClient(configKey = "core")
@RegisterProvider(ServiceTokenClientFilter.class)
@Path("/internal")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
interface CoreInternalClient {

    @GET
    @Path("/authz/{tenantId}/{sub}")
    AuthzContextDto authzContext(@PathParam("tenantId") UUID tenantId, @PathParam("sub") String sub);

    @GET
    @Path("/teams/{teamId}/roster")
    TeamRosterDto teamRoster(@PathParam("teamId") UUID teamId, @QueryParam("tenantId") UUID tenantId);

    @POST
    @Path("/players:batch")
    PlayerBatchResponseDto players(@QueryParam("tenantId") UUID tenantId, PlayerBatchRequestDto request);

    /** {@code timezone} is not in core's contract yet; it is read when core starts sending it. */
    record AuthzContextDto(String sub, UUID personId, UUID tenantId, String tenantStatus, List<String> roles,
            List<UUID> staffTeamIds, List<UUID> linkedPlayerIds, UUID ownPlayerId, String timezone) {}

    record TeamRosterDto(UUID teamId, String teamName, List<RosterPlayerDto> players, List<RosterStaffDto> staff) {}

    record RosterPlayerDto(UUID playerId, String displayName) {}

    record RosterStaffDto(UUID personId, String role) {}

    record PlayerBatchRequestDto(List<UUID> playerIds) {}

    record PlayerBatchResponseDto(List<PlayerBriefDto> players) {}

    record PlayerBriefDto(UUID id, String displayName, String status) {}
}
