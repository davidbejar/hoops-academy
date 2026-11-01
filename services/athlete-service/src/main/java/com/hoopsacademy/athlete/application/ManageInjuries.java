package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.Injury;
import com.hoopsacademy.athlete.domain.InjuryId;
import com.hoopsacademy.athlete.domain.InjurySeverity;
import com.hoopsacademy.athlete.domain.InjuryStatus;
import com.hoopsacademy.athlete.domain.PlayerAvailability;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.Optional;

/** Injuries of players and the availability derived from them. */
@ApplicationScoped
public class ManageInjuries {

    public record NewInjury(PlayerId playerId, LocalDate occurredOn, String bodyPart, String description,
            InjurySeverity severity, LocalDate expectedReturnOn) {}

    /** A partial change: {@code Optional.empty()} = untouched, a present optional holding null = clear. */
    public record InjuryChange(Optional<LocalDate> occurredOn, Optional<String> bodyPart,
            Optional<Optional<String>> description, Optional<InjurySeverity> severity,
            Optional<Optional<LocalDate>> expectedReturnOn, Optional<Optional<LocalDate>> actualReturnOn,
            Optional<InjuryStatus> status) {}

    public record Search(Optional<PlayerId> player, Optional<TeamId> team, Optional<InjuryStatus> status, int page,
            int size) {}

    private final InjuryRepository injuries;
    private final RosterPort roster;
    private final HealthAccess access;
    private final TenantClock clock;

    public ManageInjuries(InjuryRepository injuries, RosterPort roster, HealthAccess access, TenantClock clock) {
        this.injuries = injuries;
        this.roster = roster;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public Injury create(AuthzContext caller, Actor actor, NewInjury request) {
        access.requireWriteAsFamily(caller, request.playerId());
        requirePlayer(caller, request.playerId());
        Injury injury = Injury.report(request.playerId(), request.occurredOn(), request.bodyPart(), request.description(),
                request.severity(), request.expectedReturnOn(), actor, clock.now());
        injuries.save(injury);
        return injury;
    }

    @Transactional
    public Injury get(AuthzContext caller, InjuryId id) {
        Injury injury = injuries.find(id).orElseThrow(() -> new NotFoundException("Injury not found"));
        access.requireRead(caller, injury.playerId(), "Injury");
        return injury;
    }

    @Transactional
    public Injury update(AuthzContext caller, InjuryId id, InjuryChange change) {
        Injury current = get(caller, id);
        access.requireWriteAsFamily(caller, current.playerId());
        Injury changed = current.changedTo(
                change.occurredOn().orElse(current.occurredOn()),
                change.bodyPart().orElse(current.bodyPart()),
                Patches.apply(change.description(), current.description()),
                change.severity().orElse(current.severity()),
                Patches.apply(change.expectedReturnOn(), current.expectedReturnOn().orElse(null)),
                Patches.apply(change.actualReturnOn(), current.actualReturnOn().orElse(null)),
                change.status().orElse(current.status()),
                clock.now());
        injuries.save(changed);
        return changed;
    }

    /** ADMIN and staff of the player's team only: a parent reports and corrects but does not delete. */
    @Transactional
    public void delete(AuthzContext caller, InjuryId id) {
        Injury injury = get(caller, id);
        access.requireManage(caller, injury.playerId());
        injuries.delete(id);
    }

    @Transactional
    public PageResult<Injury> search(AuthzContext caller, Search search) {
        var scope = access.listScope(caller, search.player(), search.team());
        return injuries.search(scope, search.status(), search.page(), search.size());
    }

    /** Is the player available today? Visible to everyone who may read the player's data. */
    @Transactional
    public PlayerAvailability availability(AuthzContext caller, PlayerId player) {
        access.requireRead(caller, player, "Player");
        requirePlayer(caller, player);
        return PlayerAvailability.of(player, injuries.openOf(player), clock.today(caller.tenantId()));
    }

    private void requirePlayer(AuthzContext caller, PlayerId player) {
        if (!roster.playerExists(caller.tenantId(), player)) {
            throw new NotFoundException("Player not found");
        }
    }
}
