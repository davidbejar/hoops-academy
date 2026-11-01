package com.hoopsacademy.common.tenancy;

import io.agroal.api.AgroalDataSource;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.QueryParam;
import java.util.Map;

/** Test-only endpoints exposing what the tenant filter bound. */
@Path("/")
public class TenancyProbeResource {

    @Inject
    TenantContext tenantContext;

    @Inject
    TenantScope tenantScope;

    @Inject
    AgroalDataSource dataSource;

    /** Shape of /internal/teams/{teamId}/roster: tenant as query parameter, no tenant header on /internal. */
    @GET
    @Path("internal/probe/tenant-setting")
    public String internalTenantSetting(@QueryParam("tenantId") String tenantId) {
        String seen = tenantScope.runAs(TenantId.parse(tenantId), () -> SessionProbe.of(dataSource).tenantSetting());
        return seen + "|bound-after=" + tenantContext.tenantId().isPresent();
    }

    @GET
    @Path("api/probe/whoami")
    public Map<String, Object> whoAmI() {
        AuthzContext authz = tenantContext.requireAuthz();
        return Map.of(
                "tenantId", tenantContext.requireTenantId().toString(),
                "subject", authz.subject(),
                "roles", authz.roles());
    }

    @Inject
    io.quarkus.security.identity.SecurityIdentity identity;

    /** The caller id as every service derives it (CallerSubject). */
    @GET
    @Path("api/probe/me/subject")
    @Authenticated
    public String subject() {
        return CallerSubject.of(identity);
    }

    /** The logging MDC as a log statement in a resource would see it. */
    @GET
    @Path("api/probe/mdc")
    public String mdcTenant() {
        return String.valueOf(org.jboss.logging.MDC.get("tenantId"));
    }

    /** Like {@code /api/core/me}: an /api path declared tenant-exempt in hoops.tenancy.exempt-paths. */
    @GET
    @Path("api/probe/me")
    @Authenticated
    public String exemptMe() {
        return "tenant-bound=" + tenantContext.tenantId().isPresent();
    }

    @GET
    @Path("api/probe/me/details")
    @Authenticated
    public String belowAnExemptPath() {
        return "tenant-bound=" + tenantContext.tenantId().isPresent();
    }

    @GET
    @Path("platform/probe/ping")
    @Authenticated
    public String platformPing() {
        return "tenant-bound=" + tenantContext.tenantId().isPresent();
    }

    @GET
    @Path("internal/probe/ping")
    public String internalPing() {
        return "tenant-bound=" + tenantContext.tenantId().isPresent();
    }

    @GET
    @Path("apiary/probe/ping")
    public String lookalikePath() {
        return "tenant-bound=" + tenantContext.tenantId().isPresent();
    }
}
