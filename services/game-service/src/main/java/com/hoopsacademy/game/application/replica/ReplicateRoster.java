package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.replica.ReplicaOutcome;
import com.hoopsacademy.common.tenancy.TenantScope;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Applies core's roster events to the replica (ADR-0037). Each event runs in its own transaction bound to the
 * event's tenant ({@link TenantScope}), never the caller's: a known event id changes nothing, a stale event (older
 * than the stored row) is recorded as known but changes nothing either. Records that break their contract never get
 * here: common's {@code ReplicaConsumer} parks them (WP130).
 */
@ApplicationScoped
public class ReplicateRoster {

    private final TenantScope tenantScope;
    private final RosterReplica replica;

    public ReplicateRoster(TenantScope tenantScope, RosterReplica replica) {
        this.tenantScope = tenantScope;
        this.replica = replica;
    }

    public ReplicaOutcome apply(RosterEvent event) {
        return tenantScope.runAs(event.envelope().tenantId(), () -> {
            if (!replica.markApplied(event.envelope(), event.topic())) {
                return ReplicaOutcome.DUPLICATE;
            }
            return replica.save(event) ? ReplicaOutcome.APPLIED : ReplicaOutcome.STALE;
        });
    }
}
