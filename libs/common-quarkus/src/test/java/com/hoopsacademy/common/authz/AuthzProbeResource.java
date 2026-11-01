package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import java.util.UUID;

/** Test-only endpoints guarded by @RequiresTenantRole and Authz checks. */
@Path("/api/probe/authz")
@RequiresTenantRole({TenantRole.COACH, TenantRole.ASSISTANT_COACH})
public class AuthzProbeResource {

    @Inject
    Authz authz;

    @GET
    @Path("staff-area")
    public String staffArea() {
        return "staff";
    }

    @GET
    @Path("admin-only")
    @RequiresTenantRole(TenantRole.ADMIN)
    public String adminOnly() {
        return "admin";
    }

    @GET
    @Path("teams/{teamId}")
    public String team(@PathParam("teamId") UUID teamId) {
        authz.require(authz.isStaffOf(teamId), "Not staff of this team");
        return "team";
    }

    @GET
    @Path("players/{playerId}")
    @RequiresTenantRole({TenantRole.PARENT, TenantRole.PLAYER, TenantRole.COACH})
    public String player(@PathParam("playerId") UUID playerId) {
        authz.require(authz.isGuardianOf(playerId) || authz.isSelf(playerId), "Not linked to this player");
        return "player";
    }
}
