package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.vertx.core.http.HttpHeaders;
import io.vertx.ext.web.RoutingContext;

/** Ends a Vert.x route (before any resource runs) with a Problem body. */
final class RouteProblems {

    private RouteProblems() {
    }

    static void end(RoutingContext ctx, Problem problem, ObjectMapper mapper) {
        ctx.response()
                .setStatusCode(problem.status())
                .putHeader(HttpHeaders.CONTENT_TYPE, Problem.MEDIA_TYPE)
                .end(json(problem, mapper));
    }

    private static String json(Problem problem, ObjectMapper mapper) {
        try {
            return mapper.writeValueAsString(problem);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Problem is always serialisable", e);
        }
    }
}
