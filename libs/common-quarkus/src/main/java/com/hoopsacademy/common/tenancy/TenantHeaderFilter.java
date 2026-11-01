package com.hoopsacademy.common.tenancy;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.problem.ProblemType;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.util.Optional;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Binds the tenant for every {@code /api/**} request: the caller must be authenticated (401), send a valid
 * tenant header (400) and be a member of that tenant (404 — never 403, so tenant existence is not revealed).
 * {@code /platform/**}, {@code /internal/**} and non-REST paths ({@code /q/**}) are not tenant scoped.
 */
@Provider
@Priority(Priorities.AUTHENTICATION + 10)
public class TenantHeaderFilter implements ContainerRequestFilter {

    private final SecurityIdentity identity;
    private final TenantContext tenantContext;
    private final AuthzContextResolver resolver;
    private final String tenantHeader;

    public TenantHeaderFilter(
            SecurityIdentity identity,
            TenantContext tenantContext,
            AuthzContextResolver resolver,
            @ConfigProperty(name = "hoops.tenancy.header", defaultValue = "X-Tenant-Id") String tenantHeader) {
        this.identity = identity;
        this.tenantContext = tenantContext;
        this.resolver = resolver;
        this.tenantHeader = tenantHeader;
    }

    @Override
    public void filter(ContainerRequestContext request) {
        if (!TenantScopedPaths.isTenantScoped(request.getUriInfo().getPath())) {
            return;
        }
        if (identity.isAnonymous()) {
            request.abortWith(unauthorized(request));
            return;
        }
        String rawTenant = request.getHeaderString(tenantHeader);
        if (rawTenant == null || rawTenant.isBlank()) {
            request.abortWith(problem(ProblemType.BAD_REQUEST, "Header " + tenantHeader + " is required", request));
            return;
        }
        Optional<TenantId> tenant = parse(rawTenant);
        if (tenant.isEmpty()) {
            request.abortWith(problem(ProblemType.BAD_REQUEST, "Header " + tenantHeader + " must be a UUID", request));
            return;
        }
        bindMembership(tenant.get(), request);
    }

    private void bindMembership(TenantId tenant, ContainerRequestContext request) {
        tenantContext.bindTenant(tenant);
        Optional<AuthzContext> membership = resolver.resolve(CallerSubject.of(identity), tenant);
        if (membership.isEmpty()) {
            tenantContext.clear();
            request.abortWith(problem(ProblemType.NOT_FOUND, null, request));
            return;
        }
        tenantContext.bindAuthz(membership.get());
    }

    private static Optional<TenantId> parse(String rawTenant) {
        try {
            return Optional.of(TenantId.parse(rawTenant));
        } catch (InvalidTenantIdException e) {
            return Optional.empty();
        }
    }

    private static Response unauthorized(ContainerRequestContext request) {
        return Response.fromResponse(problem(ProblemType.UNAUTHORIZED, null, request))
                .header(HttpHeaders.WWW_AUTHENTICATE, "Bearer")
                .build();
    }

    private static Response problem(ProblemType type, String detail, ContainerRequestContext request) {
        return Problem.of(type, detail, request.getUriInfo().getRequestUri().getRawPath()).toResponse();
    }
}
