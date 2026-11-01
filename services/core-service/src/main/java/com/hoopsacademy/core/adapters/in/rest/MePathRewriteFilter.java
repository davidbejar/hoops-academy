package com.hoopsacademy.core.adapters.in.rest;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.ext.Provider;

/**
 * {@code /api/core/me} is the one {@code /api/**} operation without {@code X-Tenant-Id} (it lists the caller's
 * tenants). The common TenantHeaderFilter treats every {@code /api/**} path as tenant scoped, so this pre-matching
 * filter routes the public path to {@link MeResource#PATH}, which that filter skips. Authentication is unaffected.
 */
@Provider
@PreMatching
@Priority(Priorities.AUTHENTICATION - 10)
public class MePathRewriteFilter implements ContainerRequestFilter {

    static final String PUBLIC_PATH = "/api/core/me";

    @Override
    public void filter(ContainerRequestContext request) {
        String path = request.getUriInfo().getPath();
        if (PUBLIC_PATH.equals(path) || (PUBLIC_PATH + "/").equals(path)) {
            request.setRequestUri(request.getUriInfo().getRequestUriBuilder().replacePath(MeResource.PATH).build());
        }
    }
}
