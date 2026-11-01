package com.hoopsacademy.core.domain.tenant;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.util.regex.Pattern;

/** URL-safe unique handle of a tenant: 3..50 chars, lowercase letters, digits and inner hyphens. */
public record TenantSlug(String value) {

    private static final Pattern FORMAT = Pattern.compile("^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$");

    public TenantSlug {
        if (value == null || !FORMAT.matcher(value).matches()) {
            throw new DomainRuleViolation("Slug must be 3-50 lowercase letters, digits or inner hyphens",
                    "INVALID_SLUG");
        }
    }

    public static TenantSlug of(String value) {
        return new TenantSlug(value);
    }

    @Override
    public String toString() {
        return value;
    }
}
