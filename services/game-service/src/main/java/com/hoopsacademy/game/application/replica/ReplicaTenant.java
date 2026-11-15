package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import java.time.ZoneId;
import java.util.Optional;

/**
 * The academy as the replica knows it.
 *
 * @param name the academy's name, null when the row was written before the replica kept it (WP117)
 */
public record ReplicaTenant(TenantStatus status, ZoneId timezone, String name) {

    /** A tenant whose name the replica does not know. */
    public ReplicaTenant(TenantStatus status, ZoneId timezone) {
        this(status, timezone, null);
    }

    public boolean active() {
        return status == TenantStatus.ACTIVE;
    }

    /** The name when the replica knows one that is not blank. */
    public Optional<String> knownName() {
        return Optional.ofNullable(name).filter(n -> !n.isBlank());
    }
}
