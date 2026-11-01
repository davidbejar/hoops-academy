package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.MergePatch;
import com.hoopsacademy.core.application.roster.TeamService;
import com.hoopsacademy.core.application.roster.TeamService.NewTeam;
import com.hoopsacademy.core.application.roster.TeamService.TeamQuery;
import com.hoopsacademy.core.application.roster.TeamStaffService;
import com.hoopsacademy.core.application.roster.TeamStaffService.StaffView;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamChanges;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Teams and team staff (any member reads; ADMIN writes). Assignments live in {@link TeamPlayerResource}. */
@Path("/api/core/teams")
@Produces(MediaType.APPLICATION_JSON)
public class TeamResource {

    /** Contract {@code CreateTeamRequest}. */
    public record CreateTeamRequest(@NotNull UUID seasonId, @NotNull @Size(min = 1, max = Team.MAX_NAME) String name,
            @Size(max = Team.MAX_ALIAS) String alias, @NotNull UUID ageCategoryId,
            @NotNull @Pattern(regexp = Constraints.GENDER_POLICY) String genderPolicy) {}

    /** Contract {@code TeamStaffAssignment}. */
    public record TeamStaffAssignment(@NotNull @Pattern(regexp = Constraints.STAFF_ROLE) String role) {}

    /** Contract {@code TeamStaffMember}. */
    public record TeamStaffMemberDto(RefDtos.PersonRef person, StaffRole role, LocalDate since) {

        static TeamStaffMemberDto of(StaffView view) {
            return new TeamStaffMemberDto(new RefDtos.PersonRef(view.member().person().value(), view.displayName()),
                    view.member().role(), view.member().since());
        }
    }

    private final TeamService teams;
    private final TeamStaffService staff;

    public TeamResource(TeamService teams, TeamStaffService staff) {
        this.teams = teams;
        this.staff = staff;
    }

    @GET
    public TeamDto.PageDto list(@QueryParam("seasonId") UUID seasonId, @QueryParam("ageCategoryId") UUID ageCategoryId,
            @QueryParam("staffedByMe") @DefaultValue("false") boolean staffedByMe,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        TeamQuery query = new TeamQuery(Optional.ofNullable(seasonId).map(SeasonId::new),
                Optional.ofNullable(ageCategoryId).map(AgeCategoryId::new), staffedByMe);
        return TeamDto.PageDto.of(teams.list(query, new PageRequest(page, size)));
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull CreateTeamRequest request, UriInfo uri) {
        TeamDto created = TeamDto.of(teams.create(new NewTeam(new SeasonId(request.seasonId()), request.name(),
                request.alias(), new AgeCategoryId(request.ageCategoryId()), GenderPolicy.valueOf(request.genderPolicy()))));
        return Response.created(uri.getAbsolutePathBuilder().path(created.id().toString()).build()).entity(created).build();
    }

    @GET
    @Path("/{teamId}")
    public TeamDto get(@PathParam("teamId") UUID id) {
        return TeamDto.of(teams.get(new TeamId(id)));
    }

    @PATCH
    @Path("/{teamId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public TeamDto update(@PathParam("teamId") UUID id, @NotNull JsonNode body) {
        MergePatch patch = MergePatch.of(body);
        TeamChanges changes = new TeamChanges(
                patch.requiredText("name", Team.MAX_NAME),
                patch.text("alias", Team.MAX_ALIAS),
                patch.parsed("ageCategoryId", false, value -> new AgeCategoryId(UUID.fromString(value))),
                patch.parsed("genderPolicy", false, GenderPolicy::valueOf));
        patch.validate(true);
        return TeamDto.of(teams.update(new TeamId(id), changes));
    }

    @GET
    @Path("/{teamId}/staff")
    public List<TeamStaffMemberDto> staff(@PathParam("teamId") UUID team) {
        return staff.list(new TeamId(team)).stream().map(TeamStaffMemberDto::of).toList();
    }

    @PUT
    @Path("/{teamId}/staff/{personId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public TeamStaffMemberDto putStaff(@PathParam("teamId") UUID team, @PathParam("personId") UUID person,
            @Valid @NotNull TeamStaffAssignment request) {
        return TeamStaffMemberDto.of(staff.put(new TeamId(team), new PersonId(person), StaffRole.valueOf(request.role())));
    }

    @DELETE
    @Path("/{teamId}/staff/{personId}")
    public void removeStaff(@PathParam("teamId") UUID team, @PathParam("personId") UUID person) {
        staff.remove(new TeamId(team), new PersonId(person));
    }
}
