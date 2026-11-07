package com.hoopsacademy.game.application;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.SeasonEndedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.game.domain.SeasonClose;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Optional;

/**
 * When the season of a match's team has ended (ADR-0042): the day after its last day, in the academy's time zone.
 * Current staff of the team need no lookup ({@code staffTeamIds} holds only teams of seasons that have not ended) and
 * neither do its former staff ({@code historicStaffTeamIds} holds only ended ones, though their closing instant needs
 * the date); anybody else asks {@link RosterPort} for the season end. A team core does not know, or an answer without
 * the date, counts as not ended.
 */
@ApplicationScoped
public class PastSeasons {

    private final RosterPort roster;
    private final CurrentCaller caller;
    private final Clock clock;

    PastSeasons(RosterPort roster, CurrentCaller caller, Clock clock) {
        this.roster = roster;
        this.caller = caller;
        this.clock = clock;
    }

    /** The instant the team's season closed (start of the day after its last day), once that has passed. */
    public Optional<Instant> closedSince(TeamId team) {
        AuthzContext authz = caller.authz();
        if (authz.isStaffOf(team.value())) {
            return Optional.empty();
        }
        ZoneId zone = authz.timezone().orElse(ZoneOffset.UTC);
        return seasonEnd(team).map(lastDay -> SeasonClose.after(lastDay, zone))
                .filter(close -> close.hasPassed(clock.instant())).map(SeasonClose::at);
    }

    /** @throws SeasonEndedException (409) when the team's season has ended */
    public void requireOpen(TeamId team) {
        if (caller.authz().wasStaffOf(team.value()) || closedSince(team).isPresent()) {
            throw new SeasonEndedException("The season of team " + team.value() + " has ended; its matches are read-only");
        }
    }

    private Optional<LocalDate> seasonEnd(TeamId team) {
        try {
            return Optional.ofNullable(roster.teamRoster(caller.tenantId(), team).seasonEndDate());
        } catch (NotFoundException unknownTeam) {
            return Optional.empty();
        }
    }
}
