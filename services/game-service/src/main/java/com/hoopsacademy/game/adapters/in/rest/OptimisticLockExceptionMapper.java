package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.problem.ProblemType;
import jakarta.persistence.OptimisticLockException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/**
 * A concurrent change of the same match (@Version) is a 409 Problem with code CONCURRENT_MODIFICATION, not a 500.
 * Kept in this module because common-quarkus does not map persistence exceptions (see WP7 handover).
 */
public class OptimisticLockExceptionMapper {

    public static final String CODE = "CONCURRENT_MODIFICATION";

    @ServerExceptionMapper
    public Response optimisticLock(OptimisticLockException e, UriInfo uri) {
        return conflict(uri);
    }

    @ServerExceptionMapper
    public Response staleState(org.hibernate.StaleStateException e, UriInfo uri) {
        return conflict(uri);
    }

    static Response conflict(UriInfo uri) {
        return Problem.of(ProblemType.CONFLICT, "The match was changed concurrently; reload and retry",
                "/" + uri.getPath(), CODE, List.of()).toResponse();
    }
}
