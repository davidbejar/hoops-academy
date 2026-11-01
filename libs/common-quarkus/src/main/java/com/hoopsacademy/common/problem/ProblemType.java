package com.hoopsacademy.common.problem;

/** The problem types Hoops Academy services emit; {@link #uri()} is the RFC 9457 {@code type} member. */
public enum ProblemType {
    BAD_REQUEST(400, "Bad Request", "bad-request"),
    VALIDATION(400, "Validation Failed", "validation"),
    UNAUTHORIZED(401, "Unauthorized", "unauthorized"),
    FORBIDDEN(403, "Forbidden", "forbidden"),
    NOT_FOUND(404, "Not Found", "not-found"),
    CONFLICT(409, "Conflict", "conflict"),
    DOMAIN_RULE_VIOLATION(422, "Domain Rule Violation", "domain-rule-violation"),
    INTERNAL_ERROR(500, "Internal Server Error", "internal-error"),
    UPSTREAM_UNAVAILABLE(503, "Service Unavailable", "upstream-unavailable");

    private static final String URN_PREFIX = "urn:hoops:problem:";

    private final int status;
    private final String title;
    private final String slug;

    ProblemType(int status, String title, String slug) {
        this.status = status;
        this.title = title;
        this.slug = slug;
    }

    public int status() {
        return status;
    }

    public String title() {
        return title;
    }

    public String uri() {
        return URN_PREFIX + slug;
    }
}
