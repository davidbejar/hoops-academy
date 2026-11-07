package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.GuardianLinkRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.PersonChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.PlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamPlayerChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffChanged;
import com.hoopsacademy.athlete.application.replica.RosterChange.TeamStaffRemoved;
import com.hoopsacademy.athlete.application.replica.RosterChange.TenantChanged;

/**
 * Writes of the replica tables, inside a transaction bound to the event's tenant. Every upsert keys on (tenant,
 * aggregate id) and writes only when the stored row is not newer than the event ({@code occurredAt}); it answers
 * whether it wrote.
 */
public interface RosterReplicaStore {

    /** Records the event id; false when it was recorded before (a redelivery). */
    boolean markApplied(RosterEvent event);

    boolean tenant(RosterEvent event, TenantChanged change);

    boolean person(RosterEvent event, PersonChanged change);

    boolean player(RosterEvent event, PlayerChanged change);

    boolean team(RosterEvent event, TeamChanged change);

    boolean teamPlayer(RosterEvent event, TeamPlayerChanged change);

    boolean teamStaff(RosterEvent event, TeamStaffChanged change);

    boolean teamStaffRemoved(RosterEvent event, TeamStaffRemoved change);

    boolean guardianLink(RosterEvent event, GuardianLinkChanged change);

    boolean guardianLinkRemoved(RosterEvent event, GuardianLinkRemoved change);

    /** Keeps the event's aggregate as removed, with nothing but its identity (WP82). */
    boolean removed(RosterEvent event, RosterChange.Removed change);
}
