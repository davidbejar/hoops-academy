package com.hoopsacademy.common.problem;

import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

/** Test-only endpoints that fail in every way the mappers must handle. */
@Path("/probe/problems")
public class ProblemProbeResource {

    public record WidgetRequest(@NotBlank String name) {}

    @GET
    @Path("/not-found")
    public String notFound() {
        throw new NotFoundException("Widget 42 not found");
    }

    @GET
    @Path("/conflict")
    public String conflict() {
        throw new ConflictException("Widget was modified concurrently");
    }

    @GET
    @Path("/domain-rule")
    public String domainRule() {
        throw new DomainRuleViolation("Player is too old for category U12");
    }

    @GET
    @Path("/coded-domain-rule")
    public String codedDomainRule() {
        throw new DomainRuleViolation("Player is not eligible", "PLAYER_INELIGIBLE",
                List.of(new Problem.Violation("birthDate", "MISSING_BIRTH_DATE", "Birth date is required")));
    }

    @GET
    @Path("/coded-conflict")
    public String codedConflict() {
        throw new ConflictException("Request is not pending", "NOT_PENDING");
    }

    @GET
    @Path("/coded-not-found")
    public String codedNotFound() {
        throw new NotFoundException("No such team", "TEAM_NOT_FOUND");
    }

    @GET
    @Path("/access-denied")
    public String accessDenied() {
        throw new AccessDeniedException("Requires one of [ADMIN]");
    }

    @GET
    @Path("/validation")
    public String validation(@QueryParam("size") @Min(1) int size) {
        return "ok";
    }

    @POST
    @Path("/validation")
    @Consumes(MediaType.APPLICATION_JSON)
    public String validationBody(@Valid WidgetRequest request) {
        return "ok";
    }

    @GET
    @Path("/unexpected")
    public String unexpected() {
        throw new IllegalStateException("secret-internal-detail at db host 10.0.0.7");
    }

    @GET
    @Path("/optimistic-lock")
    public String optimisticLock() {
        throw new jakarta.persistence.OptimisticLockException("row version 3 != 4");
    }

    @GET
    @Path("/stale-state")
    public String staleState() {
        throw new org.hibernate.StaleObjectStateException("SampleWidget", 42);
    }

    @GET
    @Path("/wrapped-optimistic-lock")
    public String wrappedOptimisticLock() {
        throw new IllegalStateException("commit failed", new jakarta.persistence.OptimisticLockException("stale"));
    }

    @GET
    @Path("/upstream-unavailable")
    public String upstreamUnavailable() {
        throw new UpstreamUnavailableException("core-service answered 500 at 10.0.0.7", new RuntimeException());
    }

    @GET
    @Path("/platform-forbidden")
    @RolesAllowed("super_admin")
    public String platformForbidden() {
        return "ok";
    }
}
