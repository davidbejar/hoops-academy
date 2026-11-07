package com.hoopsacademy.common.problem;

import com.hoopsacademy.common.security.DenialKind;
import com.hoopsacademy.common.security.MissingSubjectException;
import com.hoopsacademy.common.security.SecurityCaller;
import com.hoopsacademy.common.security.SecurityEventLog;
import com.hoopsacademy.common.security.TokenFailureReason;
import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.UnauthorizedException;
import jakarta.persistence.OptimisticLockException;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Maps every exception leaving a resource to {@code application/problem+json}; never exposes stack traces. */
public class ProblemExceptionMappers {

    /** Problem {@code code} of a lost optimistic-locking race ({@code @Version}): reload and retry. */
    public static final String CONCURRENT_MODIFICATION = "CONCURRENT_MODIFICATION";

    private static final Logger LOG = Logger.getLogger(ProblemExceptionMappers.class);

    private final SecurityEventLog securityEvents;

    public ProblemExceptionMappers(SecurityEventLog securityEvents) {
        this.securityEvents = securityEvents;
    }

    @ServerExceptionMapper
    public Response notFound(NotFoundException e, UriInfo uri) {
        return coded(ProblemType.NOT_FOUND, e, uri);
    }

    @ServerExceptionMapper
    public Response conflict(ConflictException e, UriInfo uri) {
        return coded(ProblemType.CONFLICT, e, uri);
    }

    @ServerExceptionMapper
    public Response domainRuleViolation(DomainRuleViolation e, UriInfo uri) {
        return Problem.of(ProblemType.DOMAIN_RULE_VIOLATION, e.getMessage(), path(uri), e.code(), e.reasons())
                .toResponse();
    }

    /** Every 403 of the tenancy layer and the use cases: a {@code role} or {@code fine_grained} security event. */
    @ServerExceptionMapper
    public Response accessDenied(AccessDeniedException e, UriInfo uri) {
        securityEvents.denied(ProblemMapping.denialKindOf(e), e.getMessage());
        return coded(ProblemType.FORBIDDEN, e, uri);
    }

    @ServerExceptionMapper
    public Response securityForbidden(io.quarkus.security.ForbiddenException e, UriInfo uri) {
        return problem(ProblemType.FORBIDDEN, null, uri);
    }

    /**
     * Missing credentials on a role-protected resource (Quarkus' default answer is not a Problem). Quarkus Security
     * reports the failed check itself ({@code QuarkusSecurityEvents}).
     */
    @ServerExceptionMapper(UnauthorizedException.class)
    public Response unauthorized(UriInfo uri) {
        return Response.fromResponse(problem(ProblemType.UNAUTHORIZED, null, uri))
                .header(HttpHeaders.WWW_AUTHENTICATE, "Bearer")
                .build();
    }

    /**
     * Refused credentials. Quarkus reports the tokens it refuses itself ({@code QuarkusSecurityEvents}); a token it
     * accepted but the library refuses (no {@code sub}, {@code CallerSubject}) is logged here as {@code invalid_token}.
     */
    @ServerExceptionMapper
    public Response authenticationFailed(AuthenticationFailedException e, UriInfo uri) {
        if (MissingSubjectException.isCauseOf(e)) {
            securityEvents.denied(DenialKind.INVALID_TOKEN, SecurityCaller.UNKNOWN, TokenFailureReason.of(e));
        }
        return unauthorized(uri);
    }

    @ServerExceptionMapper
    public Response upstreamUnavailable(UpstreamUnavailableException e, UriInfo uri) {
        LOG.warnf("Upstream unavailable on %s: %s", path(uri), e.getMessage());
        return Problem.of(ProblemType.UPSTREAM_UNAVAILABLE,
                "A service this operation depends on is temporarily unavailable; please retry", path(uri),
                UpstreamUnavailableException.CODE, List.of()).toResponse();
    }

    @ServerExceptionMapper({OptimisticLockException.class, org.hibernate.StaleStateException.class})
    public Response concurrentModification(UriInfo uri) {
        return concurrentModificationProblem(uri);
    }

    @ServerExceptionMapper
    public Response constraintViolation(ConstraintViolationException e, UriInfo uri) {
        return Problem.validation(ProblemMapping.violationsOf(e.getConstraintViolations()), path(uri)).toResponse();
    }

    /** A NUL in a JSON string (SD-02): a validation Problem naming the field. */
    @ServerExceptionMapper
    public Response unsafeText(UnsafeTextException e, UriInfo uri) {
        return Problem.validation(List.of(new Problem.Violation(ProblemMapping.fieldOf(e), UnsafeText.CODE,
                UnsafeTextException.MESSAGE)), path(uri)).toResponse();
    }

    @ServerExceptionMapper
    public Response httpError(WebApplicationException e, UriInfo uri) {
        return Problem.ofStatus(e.getResponse().getStatus(), path(uri)).toResponse();
    }

    @ServerExceptionMapper
    public Response unexpected(Throwable e, UriInfo uri) {
        if (ProblemMapping.causedByConcurrentModification(e)) {
            return concurrentModificationProblem(uri);
        }
        if (ProblemMapping.causedByUnstorableText(e)) {
            return Problem.of(ProblemType.BAD_REQUEST, "The request contains text that cannot be stored", path(uri),
                    UnsafeText.CODE, List.of()).toResponse();
        }
        Problem problem = Problem.of(ProblemType.INTERNAL_ERROR, null, path(uri));
        LOG.errorf(e, "Unhandled exception on %s (traceId=%s)", problem.instance(), problem.traceId());
        return problem.toResponse();
    }

    private static Response concurrentModificationProblem(UriInfo uri) {
        return Problem.of(ProblemType.CONFLICT, "The resource was changed concurrently; reload and retry", path(uri),
                CONCURRENT_MODIFICATION, List.of()).toResponse();
    }

    private static Response coded(ProblemType type, CodedProblemException e, UriInfo uri) {
        return Problem.of(type, e.getMessage(), path(uri), e.code(), List.of()).toResponse();
    }

    private static Response problem(ProblemType type, String detail, UriInfo uri) {
        return Problem.of(type, detail, path(uri)).toResponse();
    }

    private static String path(UriInfo uri) {
        return uri.getRequestUri().getRawPath();
    }
}
