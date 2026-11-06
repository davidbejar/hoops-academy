package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.common.problem.Problem;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Problem+JSON for the service's own request exceptions; the generic ones by common-quarkus. */
public class GameExceptionMappers {

    @ServerExceptionMapper
    public Response invalidRequest(InvalidRequestException e, UriInfo uri) {
        return Problem.validation(List.of(new Problem.Violation(e.field(), e.code(), e.getMessage())),
                uri.getRequestUri().getRawPath()).toResponse();
    }
}
