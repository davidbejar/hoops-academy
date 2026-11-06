package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantScope;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.context.control.ActivateRequestContext;
import jakarta.transaction.Transactional;

/**
 * Applies core's roster events to the replica (ADR-0037). Each event runs in its own transaction bound to the
 * event's tenant ({@link TenantScope}), never the caller's: a known event id changes nothing, a stale event (older
 * than the stored row) is recorded as known but changes nothing either.
 */
@ApplicationScoped
public class ReplicateRoster {

    /** What applying one event did. */
    public enum Outcome {
        APPLIED,
        DUPLICATE,
        STALE
    }

    private final TenantScope tenantScope;
    private final RosterReplica replica;
    private final ParkedRecords parked;

    public ReplicateRoster(TenantScope tenantScope, RosterReplica replica, ParkedRecords parked) {
        this.tenantScope = tenantScope;
        this.replica = replica;
        this.parked = parked;
    }

    public Outcome apply(RosterEvent event) {
        return tenantScope.runAs(event.envelope().tenantId(), () -> {
            if (!replica.markApplied(event.envelope(), event.topic())) {
                return Outcome.DUPLICATE;
            }
            return replica.save(event) ? Outcome.APPLIED : Outcome.STALE;
        });
    }

    /**
     * Keeps a rejected record's position and reason; no tenant is bound (the record may name none). Callable from a
     * consumer thread (the persistence unit needs a request context).
     */
    @ActivateRequestContext
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void park(ParkedRecord record) {
        parked.park(record);
    }
}
