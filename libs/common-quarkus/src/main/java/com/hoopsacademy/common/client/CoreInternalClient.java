package com.hoopsacademy.common.client;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.eclipse.microprofile.rest.client.annotation.RegisterProvider;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

/**
 * core-service {@code /internal/**} (libs/contracts/openapi/core.yaml, tag Internal) for game and athlete. Calls carry
 * the tenant explicitly (path or query), never an X-Tenant-Id header, and a client-credentials token. Base URL and
 * timeouts: {@code quarkus.rest-client.core.*}, defaulting to {@code hoops.core.url} and 2 s (common-quarkus'
 * microprofile-config.properties). Use it through {@link CoreRosterClient} (cache + error mapping). There is no
 * class-level {@code @Path}: a {@code @Path("/internal")} interface would also be scanned as a server root resource and
 * shadow the service's own {@code /internal/**} resources (404).
 */
@RegisterRestClient(configKey = "core")
@RegisterProvider(ServiceTokenClientFilter.class)
@Produces(MediaType.APPLICATION_JSON)
public interface CoreInternalClient {

    @GET
    @Path("/internal/authz/{tenantId}/{sub}")
    AuthzContextDto authz(@PathParam("tenantId") String tenantId, @PathParam("sub") String sub);

    @GET
    @Path("/internal/teams/{teamId}/roster")
    TeamRosterDto teamRoster(@PathParam("teamId") UUID teamId, @QueryParam("tenantId") String tenantId);

    @POST
    @Path("/internal/players:batch")
    @Consumes(MediaType.APPLICATION_JSON)
    PlayerBatchResponseDto players(@QueryParam("tenantId") String tenantId, PlayerBatchRequestDto request);

    /**
     * Contract {@code AuthzContext}; {@code playerTeamIds}/{@code timezone} (core 2.x) and {@code historicStaffTeamIds}
     * (core 3.2.0) may be absent from an older core.
     */
    record AuthzContextDto(String sub, UUID personId, UUID tenantId, String tenantStatus, List<String> roles,
            List<UUID> staffTeamIds, List<UUID> linkedPlayerIds, UUID ownPlayerId, List<UUID> playerTeamIds,
            String timezone, List<UUID> historicStaffTeamIds) {}

    /**
     * Contract {@code TeamRoster}: open, valid assignments only; {@code seasonEndDate} (core 3.2.0, ADR-0042) is null
     * from an older core.
     */
    record TeamRosterDto(UUID tenantId, UUID teamId, UUID seasonId, String teamName, List<RosterPlayerDto> players,
            List<RosterStaffDto> staff, LocalDate seasonEndDate) {

        public TeamRosterDto {
            players = players == null ? List.of() : List.copyOf(players);
            staff = staff == null ? List.of() : List.copyOf(staff);
        }
    }

    record RosterPlayerDto(UUID playerId, String displayName, String jerseyNumber, LocalDate birthDate, String gender,
            String status) {}

    record RosterStaffDto(UUID personId, String role) {}

    record PlayerBatchRequestDto(List<UUID> playerIds) {}

    record PlayerBatchResponseDto(List<PlayerBriefDto> players) {}

    /** Contract {@code PlayerBrief}. */
    record PlayerBriefDto(UUID id, String displayName, LocalDate birthDate, String gender, String status) {}
}
