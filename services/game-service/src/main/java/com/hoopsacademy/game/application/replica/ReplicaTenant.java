package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import java.time.ZoneId;

/** The academy as the replica knows it. */
public record ReplicaTenant(TenantStatus status, ZoneId timezone) {

    public boolean active() {
        return status == TenantStatus.ACTIVE;
    }
}
