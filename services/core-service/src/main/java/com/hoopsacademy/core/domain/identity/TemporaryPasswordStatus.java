package com.hoopsacademy.core.domain.identity;

import java.time.Instant;

/**
 * State of a login's temporary password (ADR-0028): ACTIVE = issued and not used yet (it still signs in until the
 * sweep expires it); EXPIRED = not used in time, the login is disabled until a new one is issued; NONE = no temporary
 * password outstanding.
 */
public enum TemporaryPasswordStatus {
    ACTIVE, EXPIRED, NONE;

    /** From the login's timestamps: an expiry wins over the issue it ended. */
    public static TemporaryPasswordStatus of(Instant issuedAt, Instant expiredAt) {
        if (expiredAt != null) {
            return EXPIRED;
        }
        return issuedAt != null ? ACTIVE : NONE;
    }
}
