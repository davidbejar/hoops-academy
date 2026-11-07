package com.hoopsacademy.athlete.adapters.out.client;

import com.hoopsacademy.athlete.application.PlayerBrief;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.client.CoreInternalClient;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Typed;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import org.jboss.logging.Logger;

/**
 * {@link RosterPort} over common-quarkus' {@link CoreRosterClient} (core {@code /internal}, cached, 404 → not found,
 * anything else → 503 UPSTREAM_UNAVAILABLE, ADR-0008); this adapter only maps to athlete's types. The use cases get it
 * (or the replica) through {@code RosterSourceProducer} (hoops.roster.source).
 */
@ApplicationScoped
@Typed(CoreRosterAdapter.class)
public class CoreRosterAdapter implements RosterPort {

    private static final Logger LOG = Logger.getLogger(CoreRosterAdapter.class);

    private final CoreRosterClient core;

    CoreRosterAdapter(CoreRosterClient core) {
        this.core = core;
    }

    @Override
    public TeamRoster teamRoster(TenantId tenant, TeamId team) {
        CoreInternalClient.TeamRosterDto dto = core.teamRoster(tenant, team.value());
        return new TeamRoster(new TeamId(dto.teamId()), dto.teamName(),
                dto.players().stream().map(p -> new TeamRoster.RosterPlayer(new PlayerId(p.playerId()), p.displayName())).toList(),
                dto.staff().stream().map(s -> new PersonId(s.personId())).toList(), dto.seasonEndDate());
    }

    @Override
    public Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids) {
        Map<PlayerId, PlayerBrief> found = new HashMap<>();
        core.players(tenant, ids.stream().map(PlayerId::value).toList()).forEach((id, dto) -> found.put(new PlayerId(id),
                new PlayerBrief(new PlayerId(id), dto.displayName(), dto.status(), Optional.ofNullable(dto.birthDate()),
                        genderOf(dto.gender()))));
        return found;
    }

    /** Drops every cached core answer (tests, and a hook for invalidation events in v2). */
    public void clearCache() {
        core.clearCache();
    }

    private static Optional<Gender> genderOf(String gender) {
        if (gender == null || gender.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(Gender.valueOf(gender));
        } catch (IllegalArgumentException e) {
            LOG.warnf("Ignoring unknown gender '%s' from core-service", gender);
            return Optional.empty();
        }
    }
}
