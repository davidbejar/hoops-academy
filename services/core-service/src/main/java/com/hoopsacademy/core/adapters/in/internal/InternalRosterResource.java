package com.hoopsacademy.core.adapters.in.internal;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.roster.InternalRoster;
import com.hoopsacademy.core.application.roster.InternalRoster.TeamRosterView;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
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
import java.util.Set;
import java.util.UUID;

/** {@code RosterPort} endpoints for game/athlete (role {@code service}); the tenant comes from {@code tenantId}. */
@Path("/internal")
@RolesAllowed("service")
@Produces(MediaType.APPLICATION_JSON)
public class InternalRosterResource {

    /** Contract {@code PlayerBatchRequest}. */
    public record PlayerBatchRequest(@NotNull @Size(min = 1, max = 500) Set<@NotNull UUID> playerIds) {}

    /** Contract {@code PlayerBrief}. */
    public record PlayerBriefDto(UUID id, String displayName, LocalDate birthDate, Gender gender, PlayerStatus status) {

        static PlayerBriefDto of(PlayerSummary player) {
            return new PlayerBriefDto(player.id().value(), player.displayName(), player.birthDate(), player.gender(),
                    player.status());
        }
    }

    /** Contract {@code PlayerBatchResponse}. */
    public record PlayerBatchResponse(List<PlayerBriefDto> players) {}

    /** Contract {@code RosterPlayer}. */
    public record RosterPlayerDto(UUID playerId, String displayName, String jerseyNumber, LocalDate birthDate,
            Gender gender, PlayerStatus status) {}

    /** Contract {@code RosterStaff}. */
    public record RosterStaffDto(UUID personId, StaffRole role) {}

    /** Contract {@code TeamRoster}. */
    public record TeamRosterDto(UUID tenantId, UUID teamId, UUID seasonId, LocalDate seasonEndDate, String teamName,
            List<RosterPlayerDto> players, List<RosterStaffDto> staff) {

        static TeamRosterDto of(TeamRosterView view) {
            return new TeamRosterDto(view.tenant().value(), view.team().id().value(), view.team().season().value(),
                    view.seasonEnd(), view.team().name(),
                    view.players().stream().map(line -> new RosterPlayerDto(line.player().id().value(),
                            line.player().displayName(), line.jersey() == null ? null : line.jersey().value(),
                            line.player().birthDate(), line.player().gender(), line.player().status())).toList(),
                    view.staff().stream().map(member -> new RosterStaffDto(member.person().value(), member.role()))
                            .toList());
        }
    }

    private final InternalRoster roster;

    public InternalRosterResource(InternalRoster roster) {
        this.roster = roster;
    }

    @GET
    @Path("/teams/{teamId}/roster")
    public TeamRosterDto teamRoster(@PathParam("teamId") UUID team, @QueryParam("tenantId") @NotNull UUID tenant) {
        return TeamRosterDto.of(roster.teamRoster(new TenantId(tenant), new TeamId(team)));
    }

    @POST
    @Path("/players:batch")
    @Consumes(MediaType.APPLICATION_JSON)
    public PlayerBatchResponse players(@QueryParam("tenantId") @NotNull UUID tenant,
            @Valid @NotNull PlayerBatchRequest request) {
        return new PlayerBatchResponse(roster.players(new TenantId(tenant),
                request.playerIds().stream().map(PlayerId::new).toList()).stream().map(PlayerBriefDto::of).toList());
    }
}
