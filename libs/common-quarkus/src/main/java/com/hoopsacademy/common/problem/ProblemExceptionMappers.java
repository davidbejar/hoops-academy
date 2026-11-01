package com.hoopsacademy.common.problem;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.Comparator;
import java.util.List;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Maps every exception leaving a resource to {@code application/problem+json}; never exposes stack traces. */
public class ProblemExceptionMappers {

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
        Problem problem = Problem.of(ProblemType.INTERNAL_ERROR, null, path(uri));
        LOG.errorf(e, "Unhandled exception on %s (traceId=%s)", problem.instance(), problem.traceId());
        return problem.toResponse();
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
