package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.SeasonEndedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/**
 * Teams whose season has ended (the day after its last day, in the tenant's zone) are read-only history (ADR-0042).
 * Current staff of a team need no lookup ({@code staffTeamIds} holds only teams of seasons that have not ended), nor do
 * its former staff ({@code historicStaffTeamIds} only ended ones); anybody else asks {@link RosterPort} for the season
 * end. A team core does not know, or an answer without the date, counts as not ended.
 */
@ApplicationScoped
public class PastSeasons {

    private final RosterPort roster;
    private final TenantClock clock;

    public PastSeasons(RosterPort roster, TenantClock clock) {
        this.roster = roster;
        this.clock = clock;
    }

    /** @throws SeasonEndedException (409) when the season of {@code team} has ended */
    public void requireOpen(AuthzContext caller, TeamId team) {
        if (caller.isStaffOf(team.value())) {
            return;
        }
        if (caller.wasStaffOf(team.value()) || hasEnded(caller, team)) {
            throw new SeasonEndedException("The season of team " + team.value() + " has ended; its data is read-only");
        }
    }

    private boolean hasEnded(AuthzContext caller, TeamId team) {
        try {
            return roster.teamRoster(caller.tenantId(), team).seasonEnd()
                    .filter(lastDay -> lastDay.isBefore(clock.today(caller.tenantId()))).isPresent();
        } catch (NotFoundException unknownTeam) {
            return false;
        }
    }
}
