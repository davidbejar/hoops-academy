package com.hoopsacademy.common.problem;

import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.UnauthorizedException;
import jakarta.persistence.OptimisticLockException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.Comparator;
import java.util.List;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Maps every exception leaving a resource to {@code application/problem+json}; never exposes stack traces. */
public class ProblemExceptionMappers {

    /** Problem {@code code} of a lost optimistic-locking race ({@code @Version}): reload and retry. */
    public static final String CONCURRENT_MODIFICATION = "CONCURRENT_MODIFICATION";

    private static final Logger LOG = Logger.getLogger(ProblemExceptionMappers.class);

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

    @ServerExceptionMapper
    public Response accessDenied(AccessDeniedException e, UriInfo uri) {
        return coded(ProblemType.FORBIDDEN, e, uri);
    }

    @ServerExceptionMapper
    public Response securityForbidden(io.quarkus.security.ForbiddenException e, UriInfo uri) {
        return problem(ProblemType.FORBIDDEN, null, uri);
    }

    /** Missing or invalid credentials on a role-protected resource (Quarkus' default answer is not a Problem). */
    @ServerExceptionMapper({UnauthorizedException.class, AuthenticationFailedException.class})
    public Response unauthorized(UriInfo uri) {
        return Response.fromResponse(problem(ProblemType.UNAUTHORIZED, null, uri))
                .header(HttpHeaders.WWW_AUTHENTICATE, "Bearer")
                .build();
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
        return Problem.validation(violationsOf(e), path(uri)).toResponse();
    }

    @ServerExceptionMapper
    public Response httpError(WebApplicationException e, UriInfo uri) {
        return Problem.ofStatus(e.getResponse().getStatus(), path(uri)).toResponse();
    }

    @ServerExceptionMapper
    public Response unexpected(Throwable e, UriInfo uri) {
        if (causedByConcurrentModification(e)) {
            return concurrentModificationProblem(uri);
        }
        Problem problem = Problem.of(ProblemType.INTERNAL_ERROR, null, path(uri));
        LOG.errorf(e, "Unhandled exception on %s (traceId=%s)", problem.instance(), problem.traceId());
        return problem.toResponse();
    }

    /** A lost {@code @Version} race often arrives wrapped (flush at commit, RollbackException, ...). */
    private static boolean causedByConcurrentModification(Throwable e) {
        for (Throwable cause = e; cause != null; cause = cause.getCause() == cause ? null : cause.getCause()) {
            if (cause instanceof OptimisticLockException || cause instanceof org.hibernate.StaleStateException) {
                return true;
            }
        }
        return false;
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

    private static List<Problem.Violation> violationsOf(ConstraintViolationException e) {
        return e.getConstraintViolations().stream()
                .map(ProblemExceptionMappers::toViolation)
                .sorted(Comparator.comparing(Problem.Violation::field))
                .toList();
    }

    private static Problem.Violation toViolation(ConstraintViolation<?> violation) {
        return new Problem.Violation(violation.getPropertyPath().toString(), violation.getMessage());
    }
}
