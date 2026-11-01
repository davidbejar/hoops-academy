package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.AbsenceId;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.PlannedAbsence;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** Planned absences: ADMIN/staff for any player, PARENT for linked players, PLAYER for themselves. */
@ApplicationScoped
public class ManagePlannedAbsences {

    public record NewAbsence(PlayerId playerId, LocalDate fromDate, LocalDate toDate, String reason) {}

    /** A partial change: {@code Optional.empty()} = untouched, a present optional holding null = clear. */
    public record AbsenceChange(Optional<LocalDate> fromDate, Optional<LocalDate> toDate,
            Optional<Optional<String>> reason) {}

    public record Search(Optional<PlayerId> player, Optional<TeamId> team, Optional<LocalDate> from,
            Optional<LocalDate> to, int page, int size) {}

    private static final LocalDate MIN_DATE = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX_DATE = LocalDate.of(9999, 12, 31);

    private final AbsenceRepository absences;
    private final RosterPort roster;
    private final TrainingAccess access;
    private final TenantClock clock;

    public ManagePlannedAbsences(AbsenceRepository absences, RosterPort roster, TrainingAccess access,
            TenantClock clock) {
        this.absences = absences;
        this.roster = roster;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public PlannedAbsence create(AuthzContext caller, Actor actor, NewAbsence request) {
        access.requireAbsenceAccess(caller, request.playerId());
        if (!roster.playerExists(caller.tenantId(), request.playerId())) {
            throw new NotFoundException("Player not found");
        }
        PlannedAbsence absence = PlannedAbsence.announce(request.playerId(), request.fromDate(), request.toDate(),
                request.reason(), actor, clock.now());
        absences.save(absence);
        return absence;
    }

    /** A parent/player asking about an absence of someone else's player gets 404, not 403. */
    @Transactional
    public PlannedAbsence get(AuthzContext caller, AbsenceId id) {
        PlannedAbsence absence = absences.find(id).orElseThrow(() -> new NotFoundException("Planned absence not found"));
        if (!access.mayHandleAbsencesOf(caller, absence.playerId())) {
            throw new NotFoundException("Planned absence not found");
        }
        return absence;
    }

    @Transactional
    public PlannedAbsence update(AuthzContext caller, AbsenceId id, AbsenceChange change) {
        PlannedAbsence current = get(caller, id);
        PlannedAbsence changed = current.changedTo(
                change.fromDate().orElse(current.fromDate()),
                change.toDate().orElse(current.toDate()),
                Patches.apply(change.reason(), current.reason()));
        absences.save(changed);
        return changed;
    }

    @Transactional
    public void delete(AuthzContext caller, AbsenceId id) {
        absences.delete(get(caller, id).id());
    }

    /**
     * Staff roles: any player, optionally narrowed by player or team roster. Parents/players: only their own
     * players; naming another player is 403.
     */
    @Transactional
    public PageResult<PlannedAbsence> search(AuthzContext caller, Search search) {
        Set<PlayerId> scope = null;
        if (!access.hasStaffRole(caller)) {
            scope = new HashSet<>(access.relatedPlayers(caller));
            search.player().ifPresent(p -> access.requireAbsenceAccess(caller, p));
        }
        if (search.team().isPresent()) {
            scope = intersect(scope, roster.teamRoster(caller.tenantId(), search.team().get()).playerIds());
        }
        if (search.player().isPresent()) {
            scope = intersect(scope, List.of(search.player().get()));
        }
        return absences.search(scope, search.from().orElse(MIN_DATE), search.to().orElse(MAX_DATE), search.page(),
                search.size());
    }

    private static Set<PlayerId> intersect(Set<PlayerId> scope, List<PlayerId> others) {
        Set<PlayerId> result = new HashSet<>(others);
        if (scope != null) {
            result.retainAll(scope);
        }
        return result;
    }
}
