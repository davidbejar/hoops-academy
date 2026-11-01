package com.hoopsacademy.common.tenancy;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.problem.ProblemType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Tenant ids arriving as path/query parameters (e.g. on /internal endpoints) that do not parse → 400 Problem. */
public class TenancyExceptionMappers {

    @ServerExceptionMapper
    public Response invalidTenantId(InvalidTenantIdException e, UriInfo uri) {
        return Problem.of(ProblemType.BAD_REQUEST, e.getMessage(), uri.getRequestUri().getRawPath()).toResponse();
    }
}
