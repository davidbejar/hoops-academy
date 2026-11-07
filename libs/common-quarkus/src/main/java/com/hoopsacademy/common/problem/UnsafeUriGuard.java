package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import java.util.List;

/**
 * Answers a request whose URI (path or query) carries a control character, literal or percent-encoded, with a
 * {@code 400} Problem ({@value UnsafeText#CODE}) before routing, authentication or any resource (SD-02).
 */
@ApplicationScoped
public class UnsafeUriGuard {

    static final String DETAIL = "The request URI contains a control character";
    /** Before {@link RequestBodyLimit}: a refused URI needs no body check. */
    static final int ROUTE_ORDER = RequestBodyLimit.ROUTE_ORDER - 1;

    private final ObjectMapper mapper;

    public UnsafeUriGuard(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    void register(@Observes Router router) {
        router.route().order(ROUTE_ORDER).handler(this::check);
    }

    private void check(RoutingContext ctx) {
        if (UnsafeText.uriHasControlCharacter(ctx.request().uri())) {
            RouteProblems.end(ctx, Problem.of(ProblemType.BAD_REQUEST, DETAIL, ctx.request().path(), UnsafeText.CODE,
                    List.of()), mapper);
        } else {
            ctx.next();
        }
    }
}
