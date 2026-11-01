package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;

/**
 * Who may record one event (docs/domain/authz-matrix.md): ADMIN and staff of the match's team may record anything;
 * a PARENT may record player statistics of linked players and VOID events they recorded themselves, and once the
 * match is FINISHED only events their device recorded before the final whistle. Everybody else: nothing.
 */
final class EventAuthorization {

    private EventAuthorization() {}

    /** @param recorderOf person who recorded a stored (or earlier accepted) event, empty when unknown */
    static boolean mayRecord(AuthzContext caller, Match match, MatchEvent event, Function<EventId, Optional<UUID>> recorderOf) {
        if (caller.hasRole(TenantRole.ADMIN) || caller.isStaffOf(match.teamId().value())) {
            return true;
        }
        if (!caller.hasRole(TenantRole.PARENT) || recordedAfterTheFinalWhistle(match, event)) {
            return false;
        }
        return switch (event) {
            case MatchEvent.PlayerStat stat -> caller.isGuardianOf(stat.player().value());
            case MatchEvent.Void v -> recorderOf.apply(v.target()).filter(caller.personId()::equals).isPresent();
            default -> false;
        };
    }

    private static boolean recordedAfterTheFinalWhistle(Match match, MatchEvent event) {
        return match.status() == MatchStatus.FINISHED && event.meta().recordedAtClient().isAfter(match.finishedAt());
    }
}
