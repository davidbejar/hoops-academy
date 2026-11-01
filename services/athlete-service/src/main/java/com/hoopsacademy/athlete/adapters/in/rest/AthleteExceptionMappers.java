package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.application.InvalidRequestException;
import com.hoopsacademy.athlete.application.UpstreamUnavailableException;
import com.hoopsacademy.athlete.domain.TrainingRuleViolation;
import com.hoopsacademy.athlete.domain.TrainingStateConflict;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.problem.ProblemType;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.databind.exc.MismatchedInputException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Problem+JSON for the service's own exceptions; the generic ones are mapped by common-quarkus. */
public class AthleteExceptionMappers {

    @ServerExceptionMapper
    public Response invalidRequest(InvalidRequestException e, UriInfo uri) {
        return Problem.validation(List.of(new Problem.Violation(e.field(), e.code(), e.getMessage())), path(uri))
                .toResponse();
    }

    @ServerExceptionMapper
    public Response ruleViolation(TrainingRuleViolation e, UriInfo uri) {
        return Problem.of(ProblemType.DOMAIN_RULE_VIOLATION, e.getMessage(), path(uri), e.code(), List.of()).toResponse();
    }

    @ServerExceptionMapper
    public Response stateConflict(TrainingStateConflict e, UriInfo uri) {
        return Problem.of(ProblemType.CONFLICT, e.getMessage(), path(uri), e.code(), List.of()).toResponse();
    }

    @ServerExceptionMapper
    public Response upstreamUnavailable(UpstreamUnavailableException e, UriInfo uri) {
        return new Problem("urn:hoops:problem:upstream-unavailable", "Service Unavailable", 503,
                "A service this operation depends on is not available, retry shortly", path(uri), null,
                UpstreamUnavailableException.CODE, null).toResponse();
    }

    /** A body Jackson cannot read (bad JSON, wrong type, unknown enum value) is a 400 Problem, not Quarkus' default. */
    @ServerExceptionMapper
    public Response unreadableBody(MismatchedInputException e, UriInfo uri) {
        return Problem.validation(List.of(new Problem.Violation(fieldOf(e), "INVALID_VALUE", "Invalid value")), path(uri))
                .toResponse();
    }

    @ServerExceptionMapper
    public Response malformedJson(JsonParseException e, UriInfo uri) {
        return Problem.of(ProblemType.BAD_REQUEST, "Malformed JSON body", path(uri)).toResponse();
    }

    /** Missing or invalid credentials on a role-protected resource (401 must be a Problem like every other error). */
    @ServerExceptionMapper
    public Response unauthorized(io.quarkus.security.UnauthorizedException e, UriInfo uri) {
        return Problem.of(ProblemType.UNAUTHORIZED, null, path(uri)).toResponse();
    }

    @ServerExceptionMapper
    public Response authenticationFailed(io.quarkus.security.AuthenticationFailedException e, UriInfo uri) {
        return Problem.of(ProblemType.UNAUTHORIZED, null, path(uri)).toResponse();
    }

    private static String fieldOf(MismatchedInputException e) {
        return e.getPath().stream().map(ref -> ref.getFieldName() != null ? ref.getFieldName() : "[" + ref.getIndex() + "]")
                .reduce((a, b) -> b.startsWith("[") ? a + b : a + "." + b).orElse("body");
    }

    private static String path(UriInfo uri) {
        return uri.getRequestUri().getRawPath();
    }
}
