package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.runtime.configuration.MemorySize;
import io.vertx.core.http.HttpHeaders;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import java.util.List;
import java.util.Optional;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Answers a request whose declared {@code Content-Length} exceeds {@code quarkus.http.limits.max-body-size} with a
 * {@code 413} Problem ({@value #CODE}). Quarkus' own limit handler (route order {@code -2}) would answer an empty 413;
 * this route runs just before it. Chunked bodies without a length are still cut off by Quarkus itself.
 */
@ApplicationScoped
public class RequestBodyLimit {

    public static final String CODE = "REQUEST_TOO_LARGE";
    /** Just before {@code RouteConstants.ROUTE_ORDER_UPLOAD_LIMIT} (-2). */
    static final int ROUTE_ORDER = -3;

    private final Optional<MemorySize> limit;
    private final ObjectMapper mapper;

    public RequestBodyLimit(
            @ConfigProperty(name = "quarkus.http.limits.max-body-size") Optional<MemorySize> limit, ObjectMapper mapper) {
        this.limit = limit;
        this.mapper = mapper;
    }

    void register(@Observes Router router) {
        limit.ifPresent(max -> router.route().order(ROUTE_ORDER).handler(ctx -> enforce(ctx, max.asLongValue())));
    }

    private void enforce(RoutingContext ctx, long max) {
        String declared = ctx.request().getHeader(HttpHeaders.CONTENT_LENGTH);
        if (declared != null && exceeds(declared, max)) {
            reject(ctx, max);
        } else {
            ctx.next();
        }
    }

    private static boolean exceeds(String declared, long max) {
        try {
            return Long.parseLong(declared.trim()) > max;
        } catch (NumberFormatException e) {
            return false; // let Vert.x reject the malformed header
        }
    }

    private void reject(RoutingContext ctx, long max) {
        Problem problem = Problem.of(ProblemType.PAYLOAD_TOO_LARGE,
                "The request body exceeds the limit of " + max + " bytes", ctx.request().path(), CODE, List.of());
        ctx.response().putHeader(HttpHeaders.CONNECTION, "close");
        RouteProblems.end(ctx, problem, mapper);
    }
}
