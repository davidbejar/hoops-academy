package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.core.domain.shared.Require;
import java.time.DateTimeException;
import java.time.ZoneId;

/** Shared request constraints and conversions of the contract's primitive formats. */
public final class Constraints {

    public static final String LOCALE = "es|en|id";
    public static final String SLUG = "^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$";
    public static final String TENANT_ROLE = "ADMIN|COACH|ASSISTANT_COACH|PARENT|PLAYER";
    public static final String TENANT_STATUS = "ACTIVE|SUSPENDED|WITHDRAWN";
    public static final String GENDER = "MALE|FEMALE";
    public static final String GENDER_POLICY = "MALE|FEMALE|MIXED";
    public static final String STAFF_ROLE = "COACH|ASSISTANT_COACH";
    public static final String CATEGORY_CODE = "^[A-Z0-9_]{1,16}$";
    public static final String JERSEY = "^[0-9]{1,2}$";
    public static final String CASE_STATUS = "OPEN|RESOLVED";
    public static final String CASE_RESOLUTION = "REASSIGNED|REMOVED_FROM_TEAM|DISMISSED";

    private Constraints() {}

    /** IANA zone id; an unknown zone is a domain rule violation (422, code INVALID_TIMEZONE). */
    public static ZoneId zone(String id) {
        try {
            return ZoneId.of(id);
        } catch (DateTimeException e) {
            throw Require.violation("timezone", "Unknown time zone '" + id + "'");
        }
    }
}
