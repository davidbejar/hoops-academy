package com.hoopsacademy.common.tenancy;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.problem.ProblemType;
import com.hoopsacademy.common.security.DenialKind;
import com.hoopsacademy.common.security.SecurityCaller;
import com.hoopsacademy.common.security.SecurityEventLog;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Binds the tenant for every {@code /api/**} request: the caller must be authenticated (401), send a valid
 * tenant header (400) and be a member of that tenant (404 — never 403, so tenant existence is not revealed).
 * {@code /platform/**}, {@code /internal/**}, non-REST paths ({@code /q/**}) and the exact paths of
 * {@code hoops.tenancy.exempt-paths} (default {@code /api/core/me}) are not tenant scoped; authentication of those is
 * left to the resource ({@code @Authenticated}). The 401 and the 404s are security events (ADR-0043); a membership
 * that names another tenant than the requested one is never bound ({@code tenant_mismatch}, 404).
 */
@Provider
@Priority(Priorities.AUTHENTICATION + 10)
public class TenantHeaderFilter implements ContainerRequestFilter {

    private final SecurityIdentity identity;
    private final TenantContext tenantContext;
    private final AuthzContextResolver resolver;
    private final String tenantHeader;
    private final TenantScopedPaths scopedPaths;
    private final SecurityEventLog securityEvents;

    public TenantHeaderFilter(
            SecurityIdentity identity,
            TenantContext tenantContext,
            AuthzContextResolver resolver,
            SecurityEventLog securityEvents,
            @ConfigProperty(name = "hoops.tenancy.header", defaultValue = "X-Tenant-Id") String tenantHeader,
            @ConfigProperty(name = "hoops.tenancy.exempt-paths", defaultValue = "/api/core/me") List<String> exemptPaths) {
        this.identity = identity;
        this.tenantContext = tenantContext;
        this.resolver = resolver;
        this.tenantHeader = tenantHeader;
        this.scopedPaths = new TenantScopedPaths(exemptPaths);
        this.securityEvents = securityEvents;
    }

    @Override
    public void filter(ContainerRequestContext request) {
        if (!scopedPaths.isTenantScoped(request.getUriInfo().getPath())) {
            return;
        }
        if (identity.isAnonymous()) {
            securityEvents.denied(DenialKind.UNAUTHENTICATED, SecurityCaller.UNKNOWN, "no credentials");
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
        String subject = CallerSubject.of(identity);
        Optional<AuthzContext> membership = resolver.resolve(subject, tenant);
        if (membership.isEmpty()) {
            refuse(DenialKind.NOT_MEMBER, tenant, subject, "no membership in the requested tenant", request);
            return;
        }
        if (!membership.get().tenantId().equals(tenant)) {
            refuse(DenialKind.TENANT_MISMATCH, tenant, subject, "membership resolved for another tenant", request);
            return;
        }
        tenantContext.bindAuthz(membership.get());
    }

    private void refuse(DenialKind kind, TenantId tenant, String subject, String reason, ContainerRequestContext request) {
        tenantContext.clear();
        securityEvents.denied(kind, new SecurityCaller(tenant.toString(), subject, Set.of()), reason);
        request.abortWith(problem(ProblemType.NOT_FOUND, null, request));
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
