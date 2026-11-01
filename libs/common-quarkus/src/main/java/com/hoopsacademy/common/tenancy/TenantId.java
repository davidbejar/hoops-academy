package com.hoopsacademy.common.tenancy;

import java.util.Locale;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

/** Identity of a tenant (an academy). Pure value object, safe to use in service domain layers. */
public record TenantId(UUID value) {

    private static final Pattern CANONICAL_UUID =
            Pattern.compile("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

    public TenantId {
        Objects.requireNonNull(value, "tenant id value");
    }

    /** Parses the canonical 8-4-4-4-12 hex form (case-insensitive, surrounding blanks ignored). */
    public static TenantId parse(String raw) {
        if (raw == null) {
            throw new InvalidTenantIdException("missing");
        }
        String normalized = raw.strip().toLowerCase(Locale.ROOT);
        if (!CANONICAL_UUID.matcher(normalized).matches()) {
            throw new InvalidTenantIdException("not a canonical UUID");
        }
        return new TenantId(UUID.fromString(normalized));
    }

    public static TenantId random() {
        return new TenantId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
