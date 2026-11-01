package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.ManageCompletions;
import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

@Path("/api/athlete/plan-completions")
@Produces(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class PlanCompletionResource {

    private final ManageCompletions completions;
    private final TenantContext tenant;

    PlanCompletionResource(ManageCompletions completions, TenantContext tenant) {
        this.completions = completions;
        this.tenant = tenant;
    }

    @GET
    public PageDto<AssignmentDtos.CompletionResponse> list(@QueryParam("assignmentId") String assignmentId,
            @QueryParam("playerId") String playerId, @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size) {
        var result = completions.list(tenant.requireAuthz(), Requests.uuid("assignmentId", assignmentId).map(AssignmentId::new),
                Requests.uuid("playerId", playerId).map(PlayerId::new), page, size);
        return PageDto.of(result, AssignmentDtos.CompletionResponse::from);
    }
}
