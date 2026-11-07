package com.hoopsacademy.common.security;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * One authorization-failure security event (ADR-0043): what was refused, to whom, where and why. Its {@link #fields()}
 * go into the logging MDC of the event's log record, so the JSON log and the OTLP log record carry them as structured
 * attributes; {@link #message()} repeats them for plain-text readers. Never holds a token, a claim of an unverified
 * token, a name or an e-mail: the subject is the token's {@code sub} id. Every value is cleaned of control characters
 * and quotes (log injection) and cut at {@value #MAX_VALUE_LENGTH} characters.
 *
 * @param kind     what failed
 * @param tenantId the requested or bound tenant, null when none
 * @param subject  the verified caller's {@code sub}, null when unknown
 * @param roles    the caller's tenant roles (realm roles for {@link DenialKind#REALM_ROLE}), possibly empty
 * @param resource {@code METHOD /route/{template}} (the concrete path when no route matched yet), null when unknown
 * @param reason   a short developer-written reason, null when none
 */
public record AuthzDenial(DenialKind kind, String tenantId, String subject, Collection<String> roles, String resource,
        String reason) {

    /** Longest value written; longer ones end in {@code ...}. */
    public static final int MAX_VALUE_LENGTH = 200;
    /** The MDC keys of an event, in order. {@code tenantId} is the key every tenant-scoped log line uses. */
    public static final List<String> FIELD_KEYS = List.of("security.event", "security.kind", "security.outcome",
            "tenantId", "security.subject", "security.roles", "security.resource", "security.reason");

    static final String EVENT = "authz_denied";
    private static final String NONE = "-";

    public AuthzDenial {
        Objects.requireNonNull(kind, "kind");
        roles = roles == null ? List.of() : List.copyOf(roles);
    }

    /** The structured fields, keyed by {@link #FIELD_KEYS} in that order. */
    public Map<String, String> fields() {
        Map<String, String> fields = new LinkedHashMap<>();
        fields.put(FIELD_KEYS.get(0), EVENT);
        fields.put(FIELD_KEYS.get(1), kind.wireName());
        fields.put(FIELD_KEYS.get(2), Integer.toString(kind.status()));
        fields.put(FIELD_KEYS.get(3), clean(tenantId));
        fields.put(FIELD_KEYS.get(4), clean(subject));
        fields.put(FIELD_KEYS.get(5), clean(roles.stream().map(AuthzDenial::clean).sorted().collect(Collectors.joining(","))));
        fields.put(FIELD_KEYS.get(6), clean(resource));
        fields.put(FIELD_KEYS.get(7), clean(reason));
        return fields;
    }

    /** {@code authz_denied kind=.. outcome=.. tenant=.. subject=.. roles=.. resource=".." reason=".."}. */
    public String message() {
        Map<String, String> f = fields();
        return EVENT + " kind=" + f.get("security.kind") + " outcome=" + f.get("security.outcome")
                + " tenant=" + f.get("tenantId") + " subject=" + f.get("security.subject")
                + " roles=" + f.get("security.roles") + " resource=\"" + f.get("security.resource")
                + "\" reason=\"" + f.get("security.reason") + "\"";
    }

    private static String clean(String value) {
        if (value == null || value.isBlank()) {
            return NONE;
        }
        StringBuilder out = new StringBuilder(Math.min(value.length(), MAX_VALUE_LENGTH));
        value.strip().codePoints()
                .map(c -> Character.isISOControl(c) ? '_' : c == '"' ? '\'' : c)
                .forEach(out::appendCodePoint);
        String cleaned = out.toString();
        return cleaned.length() <= MAX_VALUE_LENGTH ? cleaned : cleaned.substring(0, MAX_VALUE_LENGTH - 3) + "...";
    }
}
