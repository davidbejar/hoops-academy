package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.PersonChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.PlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamPlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.TenantChanged;
import com.hoopsacademy.common.tenancy.TenantScope;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Applies one core roster event to the replica, in a transaction bound to the EVENT's tenant (RLS): idempotent (a
 * known eventId changes nothing) and ordered per aggregate (an event older than the stored state changes nothing). A
 * tenant event also refreshes the tenant registry's zone, so the nightly job knows tenants before anyone calls; a
 * tenant removal leaves the registry alone (the tenant has nothing to materialise, its replica rows are unreadable).
 */
@ApplicationScoped
public class ApplyRosterEvent {

    /** What applying did. */
    public enum Outcome {
        /** The replica now holds the event's state. */
        APPLIED,
        /** The eventId was applied before (a redelivery); nothing changed. */
        DUPLICATE,
        /** The replica holds a newer state of the aggregate; nothing changed. */
        STALE
    }

    private final TenantScope tenantScope;
    private final RosterReplicaStore store;
    private final TenantRegistry registry;

    public ApplyRosterEvent(TenantScope tenantScope, RosterReplicaStore store, TenantRegistry registry) {
        this.tenantScope = tenantScope;
        this.store = store;
        this.registry = registry;
    }

    public Outcome apply(RosterEvent event) {
        return tenantScope.runAs(event.tenant(), () -> {
            if (!store.markApplied(event)) {
                return Outcome.DUPLICATE;
            }
            return write(event) ? Outcome.APPLIED : Outcome.STALE;
        });
    }

    private boolean write(RosterEvent event) {
        return switch (event.change()) {
            case TenantChanged c -> tenant(event, c);
            case PersonChanged c -> store.person(event, c);
            case PlayerChanged c -> store.player(event, c);
            case TeamChanged c -> store.team(event, c);
            case TeamPlayerChanged c -> store.teamPlayer(event, c);
            case TeamStaffChanged c -> store.teamStaff(event, c);
            case TeamStaffRemoved c -> store.teamStaffRemoved(event, c);
            case GuardianLinkChanged c -> store.guardianLink(event, c);
            case GuardianLinkRemoved c -> store.guardianLinkRemoved(event, c);
            case RosterChange.Removed c -> store.removed(event, c);
        };
    }

    private boolean tenant(RosterEvent event, TenantChanged change) {
        boolean written = store.tenant(event, change);
        if (written) {
            registry.register(event.tenant(), change.timezone());
        }
        return written;
    }
}
