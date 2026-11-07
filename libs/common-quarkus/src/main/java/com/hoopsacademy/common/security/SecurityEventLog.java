package com.hoopsacademy.common.security;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.arc.Arc;
import io.quarkus.vertx.http.runtime.CurrentVertxRequest;
import io.vertx.core.http.HttpServerRequest;
import io.vertx.core.http.impl.HttpServerRequestInternal;
import io.vertx.ext.web.RoutingContext;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.Map;
import org.jboss.logging.Logger;
import org.jboss.logging.MDC;

/**
 * Writes the security events of ADR-0043: one WARN record per authentication or authorization failure in the log
 * category {@value #CATEGORY}, its fields in the MDC for the duration of the record (so the JSON console log and the
 * OTLP log export carry them as structured attributes), and counts it in {@value #METRIC} (Prometheus
 * {@code hoops_authz_denied_total{kind}}; every kind is registered at start, so a rate is defined from zero).
 */
@ApplicationScoped
public class SecurityEventLog {

    /** Log category of the security events. */
    public static final String CATEGORY = "hoops.security";
    /** Micrometer name of the denial counter, tag {@code kind}. */
    public static final String METRIC = "hoops.authz.denied";
    /**
     * Where Quarkus REST keeps the matched route template ({@code /teams/{teamId}}) of a request: a local of the
     * request's Vert.x context, the same value Quarkus tags its HTTP metrics and spans with ({@code uri},
     * {@code http.route}). {@code AuthzDenialEventsTest} pins it.
     */
    static final String ROUTE_TEMPLATE_KEY = "UrlPathTemplate";

    private static final Logger LOG = Logger.getLogger(CATEGORY);

    private final Map<DenialKind, Counter> counters = new EnumMap<>(DenialKind.class);
    private final SecurityCallerSource callers;
    private final CurrentVertxRequest currentRequest;

    public SecurityEventLog(MeterRegistry registry, SecurityCallerSource callers, CurrentVertxRequest currentRequest) {
        this.callers = callers;
        this.currentRequest = currentRequest;
        for (DenialKind kind : DenialKind.values()) {
            counters.put(kind, Counter.builder(METRIC)
                    .description("Authentication and authorization failures answered to callers, by kind (ADR-0043)")
                    .tag("kind", kind.wireName())
                    .register(registry));
        }
    }

    /** A denial of the current request's caller as the tenancy layer bound it. */
    public void denied(DenialKind kind, String reason) {
        denied(kind, callers.current(), reason);
    }

    /** A denial of {@code caller} in the current request. */
    public void denied(DenialKind kind, SecurityCaller caller, String reason) {
        denied(kind, caller, null, reason);
    }

    /** A denial of {@code caller} in the request of {@code request} (null: the current request, if any). */
    public void denied(DenialKind kind, SecurityCaller caller, RoutingContext request, String reason) {
        RoutingContext where = request == null ? currentRoutingContext() : request;
        write(new AuthzDenial(kind, caller.tenantId(), caller.subject(), caller.roles(), resourceOf(where), reason));
    }

    private void write(AuthzDenial denial) {
        Map<String, Object> previous = new HashMap<>();
        denial.fields().forEach((key, value) -> {
            previous.put(key, MDC.get(key));
            MDC.put(key, value);
        });
        try {
            LOG.warn(denial.message());
        } finally {
            previous.forEach((key, value) -> {
                if (value == null) {
                    MDC.remove(key);
                } else {
                    MDC.put(key, value);
                }
            });
        }
        counters.get(denial.kind()).increment();
    }

    private RoutingContext currentRoutingContext() {
        return Arc.container().requestContext().isActive() ? currentRequest.getCurrent() : null;
    }

    /** {@code METHOD /route/{template}}, the normalised path before a route matched, null without a request. */
    static String resourceOf(RoutingContext request) {
        if (request == null) {
            return null;
        }
        String template = routeTemplate(request.request());
        return request.request().method().name() + " " + (template == null ? request.normalizedPath() : template);
    }

    @SuppressWarnings("deprecation") // Context.getLocal(Object): the API Quarkus REST stores the template with
    private static String routeTemplate(HttpServerRequest request) {
        if (request instanceof HttpServerRequestInternal internal && internal.context() != null
                && internal.context().getLocal(ROUTE_TEMPLATE_KEY) instanceof String route && !route.isBlank()) {
            return route;
        }
        return null;
    }
}
