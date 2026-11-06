package com.hoopsacademy.core.application.events;

import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;

/** An aggregate a transaction changed; its event is built from its state at the end of the transaction. */
public sealed interface RosterChange {

    record Person(PersonId id) implements RosterChange {}

    record Player(PlayerId id) implements RosterChange {}

    record Team(TeamId id) implements RosterChange {}

    /** The season's dates are part of each of its teams' state. */
    record Season(SeasonId id) implements RosterChange {}

    record TeamPlayer(TeamPlayerId id) implements RosterChange {}

    record TeamStaff(TeamId team, PersonId person) implements RosterChange {}

    /** The ends are kept for the removed event: the row is gone by then. */
    record GuardianLink(GuardianLinkId id, PersonId guardian, PlayerId player) implements RosterChange {}

    /** The bound tenant's own record. */
    record Tenant() implements RosterChange {}
}
