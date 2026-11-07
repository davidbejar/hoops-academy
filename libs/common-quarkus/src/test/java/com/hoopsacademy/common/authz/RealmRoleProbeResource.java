package com.hoopsacademy.common.authz;

import jakarta.annotation.security.RolesAllowed;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

/** Test-only endpoint guarded by a realm role, like core's /platform and the services' /internal APIs. */
@Path("/platform/probe/realm-role")
public class RealmRoleProbeResource {

    @GET
    @RolesAllowed("super_admin")
    public String superAdminOnly() {
        return "platform";
    }
}
