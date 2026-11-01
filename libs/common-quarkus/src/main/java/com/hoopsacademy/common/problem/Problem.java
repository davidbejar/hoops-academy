package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.ws.rs.core.Response;
import java.util.List;
import org.jboss.logging.MDC;

/**
 * RFC 9457 problem details. Serialized as {@code application/problem+json}; absent members are omitted.
 * {@code traceId} is taken from the logging MDC, which quarkus-opentelemetry populates when present.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record Problem(
        String type,
        String title,
        int status,
        String detail,
        String instance,
        String traceId,
        String code,
        List<Violation> violations) {

    public static final String MEDIA_TYPE = "application/problem+json";
    static final String TRACE_ID_MDC_KEY = "traceId";
    private static final String ABOUT_BLANK = "about:blank";

    /** A failed field constraint (400) or rule reason (422); {@code field} and {@code code} are optional. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record Violation(String field, String code, String message) {

        public Violation(String field, String message) {
            this(field, null, message);
        }
    }

    public static Problem of(ProblemType type, String detail, String instance) {
        return of(type, detail, instance, null, List.of());
    }

    /** @param code machine-readable reason or null; @param violations rule reasons, omitted when empty */
    public static Problem of(ProblemType type, String detail, String instance, String code, List<Violation> violations) {
        return new Problem(type.uri(), type.title(), type.status(), detail, instance, currentTraceId(), code,
                violations.isEmpty() ? null : List.copyOf(violations));
    }

    /** A problem for a plain HTTP status that has no Hoops-specific semantics (e.g. 405, 415). */
    public static Problem ofStatus(int status, String instance) {
        return new Problem(ABOUT_BLANK, reasonPhrase(status), status, null, instance, currentTraceId(), null, null);
    }

    public static Problem validation(List<Violation> violations, String instance) {
        return of(ProblemType.VALIDATION, "Request validation failed", instance, null, violations);
    }

    public Response toResponse() {
        return Response.status(status).type(MEDIA_TYPE).entity(this).build();
    }

    private static String reasonPhrase(int status) {
        Response.Status known = Response.Status.fromStatusCode(status);
        return known != null ? known.getReasonPhrase() : "HTTP " + status;
    }

    private static String currentTraceId() {
        Object traceId = MDC.get(TRACE_ID_MDC_KEY);
        return traceId != null ? traceId.toString() : null;
    }
}
