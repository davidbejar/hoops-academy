package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.game.application.UpstreamUnavailableException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** core-service unreachable or failing: 503 Problem with code UPSTREAM_UNAVAILABLE (no internals in the detail). */
public class UpstreamExceptionMapper {

    @ServerExceptionMapper
    public Response upstreamUnavailable(UpstreamUnavailableException e, UriInfo uri) {
        Problem problem = new Problem("urn:hoops:problem:upstream-unavailable", "Service Unavailable", 503,
                "A dependent service is temporarily unavailable; please retry", "/" + uri.getPath(), null,
                UpstreamUnavailableException.CODE, null);
        return problem.toResponse();
    }
}
