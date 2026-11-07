package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.Authz;
import com.hoopsacademy.common.problem.SeasonEndedException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Teams of ended seasons are read-only history (ADR-0042): every write on them answers 409 {@code SEASON_ENDED} to the
 * callers who could write the team otherwise (ADMIN, its coach then); everybody else keeps 403. "Ended" is
 * {@link Season#hasEnded} in the academy's time zone, so an admin reopens a season by moving its end date.
 */
@ApplicationScoped
public class PastSeasons {

    private final SeasonRepository seasons;
    private final TenantToday calendar;
    private final RosterAuthz rosterAuthz;
    private final Authz authz;

    public PastSeasons(SeasonRepository seasons, TenantToday calendar, RosterAuthz rosterAuthz, Authz authz) {
        this.seasons = seasons;
        this.calendar = calendar;
        this.rosterAuthz = rosterAuthz;
        this.authz = authz;
    }

    /** The seasons among {@code ids} that have ended today. */
    public Set<SeasonId> ended(Collection<SeasonId> ids) {
        LocalDate today = calendar.today();
        Map<SeasonId, Season> byId = seasons.listNewestFirst().stream()
                .collect(Collectors.toMap(Season::id, Function.identity()));
        return ids.stream().filter(id -> byId.containsKey(id) && byId.get(id).hasEnded(today))
                .collect(Collectors.toSet());
    }

    /** For writes only ADMIN may make (the role is checked before): 409 when the team's season has ended. */
    public void requireOpenForAdmin(Team team) {
        if (hasEnded(team)) {
            throw ended(team);
        }
    }

    /**
     * For writes ADMIN or the team's COACH may make: ADMIN and the coach of the team then get 409 once its season has
     * ended, anybody else 403 (as before).
     */
    public void requireOpenForCoach(Team team) {
        if (!hasEnded(team)) {
            rosterAuthz.requireCoachOf(team.id());
            return;
        }
        boolean formerCoach = authz.hasAnyRole(TenantRole.COACH) && authz.wasStaffOf(team.id().value());
        authz.require(authz.isAdmin() || formerCoach, "Only ADMIN or the team's coach may change its roster");
        throw ended(team);
    }

    private boolean hasEnded(Team team) {
        return seasons.find(team.season()).map(season -> season.hasEnded(calendar.today())).orElse(false);
    }

    private static SeasonEndedException ended(Team team) {
        return new SeasonEndedException("The season of team " + team.id().value() + " has ended; it is read-only");
    }
}
