package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.application.roster.EligibilityCaseService;
import com.hoopsacademy.core.application.roster.EligibilityCaseService.CaseQuery;
import com.hoopsacademy.core.application.roster.EligibilityCaseService.Resolution;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.domain.eligibility.CaseResolution;
import com.hoopsacademy.core.domain.eligibility.CaseStatus;
import com.hoopsacademy.core.domain.eligibility.EligibilityCaseId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.Optional;
import java.util.UUID;

/** Eligibility cases (ADMIN and team staff read; ADMIN or the team's coach resolves). */
@Path("/api/core/eligibility-cases")
@Produces(MediaType.APPLICATION_JSON)
public class EligibilityCaseResource {

    /** Contract {@code ResolveEligibilityCaseRequest}. */
    public record ResolveRequest(@NotNull @Pattern(regexp = Constraints.CASE_RESOLUTION) String resolution,
            UUID targetTeamId, @Size(max = 500) String note) {}

    private final EligibilityCaseService cases;

    public EligibilityCaseResource(EligibilityCaseService cases) {
        this.cases = cases;
    }

    @GET
    public EligibilityCaseDto.PageDto list(@QueryParam("status") @Pattern(regexp = Constraints.CASE_STATUS) String status,
            @QueryParam("teamId") UUID team, @QueryParam("playerId") UUID player,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        CaseQuery query = new CaseQuery(Optional.ofNullable(status).map(CaseStatus::valueOf),
                Optional.ofNullable(team).map(TeamId::new), Optional.ofNullable(player).map(PlayerId::new));
        return EligibilityCaseDto.PageDto.of(cases.list(query, new PageRequest(page, size)));
    }

    @GET
    @Path("/{eligibilityCaseId}")
    public EligibilityCaseDto get(@PathParam("eligibilityCaseId") UUID id) {
        return EligibilityCaseDto.of(cases.get(new EligibilityCaseId(id)));
    }

    @POST
    @Path("/{eligibilityCaseId}/resolve")
    @Consumes(MediaType.APPLICATION_JSON)
    public EligibilityCaseDto resolve(@PathParam("eligibilityCaseId") UUID id, @Valid @NotNull ResolveRequest request) {
        return EligibilityCaseDto.of(cases.resolve(new EligibilityCaseId(id), new Resolution(
                CaseResolution.valueOf(request.resolution()), Optional.ofNullable(request.targetTeamId()).map(TeamId::new),
                request.note())));
    }
}
