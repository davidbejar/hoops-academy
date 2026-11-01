package com.hoopsacademy.athlete.adapters.out.client;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.hoopsacademy.athlete.application.MemberContext;
import com.hoopsacademy.athlete.application.PlayerBrief;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.application.TenantStatus;
import com.hoopsacademy.athlete.application.UpstreamUnavailableException;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.WebApplicationException;
import java.time.DateTimeException;
import java.time.Duration;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

/**
 * {@link RosterPort} over core-service's internal REST API (ADR-0008). Answers are cached for 30 s (configurable);
 * failures and "not found" are never cached. The REST client enforces the 2 s connect/read timeout. A 404 from core
 * is a {@link NotFoundException}; a timeout, connection failure or any other error is an
 * {@link UpstreamUnavailableException} (503 {@code UPSTREAM_UNAVAILABLE}).
 */
@ApplicationScoped
public class CoreRosterAdapter implements RosterPort {

    private static final Logger LOG = Logger.getLogger(CoreRosterAdapter.class);

    private record TeamKey(TenantId tenant, TeamId team) {}

    private record MemberKey(TenantId tenant, String subject) {}

    private record PlayerKey(TenantId tenant, PlayerId player) {}

    private final CoreInternalClient core;
    private final Cache<TeamKey, TeamRoster> rosters;
    private final Cache<MemberKey, MemberContext> members;
    private final Cache<PlayerKey, PlayerBrief> players;

    CoreRosterAdapter(@RestClient CoreInternalClient core,
            @ConfigProperty(name = "hoops.athlete.roster-cache-ttl", defaultValue = "30S") Duration ttl) {
        this.core = core;
        this.rosters = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(2_000).build();
        this.members = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(10_000).build();
        this.players = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(20_000).build();
    }

    @Override
    public TeamRoster teamRoster(TenantId tenant, TeamId team) {
        return rosters.get(new TeamKey(tenant, team), key -> toDomain(
                call(() -> core.teamRoster(team.value(), tenant.value()))));
    }

    @Override
    public Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids) {
        Map<PlayerId, PlayerBrief> found = new HashMap<>();
        List<PlayerId> missing = new ArrayList<>();
        for (PlayerId id : Set.copyOf(ids)) {
            PlayerBrief cached = players.getIfPresent(new PlayerKey(tenant, id));
            if (cached != null) {
                found.put(id, cached);
            } else {
                missing.add(id);
            }
        }
        if (!missing.isEmpty()) {
            var response = call(() -> core.players(tenant.value(),
                    new CoreInternalClient.PlayerBatchRequestDto(missing.stream().map(PlayerId::value).toList())));
            for (var dto : response.players()) {
                if (!missing.contains(new PlayerId(dto.id()))) {
                    continue; // never trust more than what was asked for
                }
                PlayerBrief brief = new PlayerBrief(new PlayerId(dto.id()), dto.displayName(), dto.status(),
                        Optional.ofNullable(dto.birthDate()), genderOf(dto.gender()));
                players.put(new PlayerKey(tenant, brief.playerId()), brief);
                found.put(brief.playerId(), brief);
            }
        }
        return found;
    }

    @Override
    public Optional<MemberContext> authzContext(TenantId tenant, String subject) {
        MemberKey key = new MemberKey(tenant, subject);
        MemberContext cached = members.getIfPresent(key);
        if (cached != null) {
            return Optional.of(cached);
        }
        try {
            MemberContext fresh = toDomain(tenant, call(() -> core.authzContext(tenant.value(), subject)));
            members.put(key, fresh);
            return Optional.of(fresh);
        } catch (NotFoundException notAMember) {
            return Optional.empty();
        }
    }

    /** Drops every cached answer (tests, and a hook for invalidation events in v2). */
    public void clearCache() {
        rosters.invalidateAll();
        members.invalidateAll();
        players.invalidateAll();
    }

    private static <T> T call(Supplier<T> request) {
        try {
            return request.get();
        } catch (WebApplicationException e) {
            if (e.getResponse().getStatus() == 404) {
                throw new NotFoundException("Not found in core-service");
            }
            LOG.warnf("core-service answered %d", e.getResponse().getStatus());
            throw new UpstreamUnavailableException("core-service answered " + e.getResponse().getStatus(), e);
        } catch (RuntimeException e) {
            LOG.warnf("core-service call failed: %s", e.toString());
            throw new UpstreamUnavailableException("core-service is not reachable", e);
        }
    }

    private static TeamRoster toDomain(CoreInternalClient.TeamRosterDto dto) {
        return new TeamRoster(new TeamId(dto.teamId()), dto.teamName(),
                dto.players().stream().map(p -> new TeamRoster.RosterPlayer(new PlayerId(p.playerId()), p.displayName())).toList(),
                dto.staff().stream().map(s -> new PersonId(s.personId())).toList());
    }

    private static MemberContext toDomain(TenantId tenant, CoreInternalClient.AuthzContextDto dto) {
        Set<TenantRole> roles = dto.roles().isEmpty()
                ? EnumSet.noneOf(TenantRole.class)
                : dto.roles().stream().map(TenantRole::valueOf).collect(Collectors.toCollection(() -> EnumSet.noneOf(TenantRole.class)));
        AuthzContext authz = new AuthzContext(dto.sub(), dto.personId(), tenant, roles, Set.copyOf(dto.staffTeamIds()),
                Set.copyOf(dto.linkedPlayerIds()), Optional.ofNullable(dto.ownPlayerId()));
        return new MemberContext(authz, TenantStatus.valueOf(dto.tenantStatus()), zoneOf(dto.timezone()));
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

    private static Optional<ZoneId> zoneOf(String timezone) {
        if (timezone == null || timezone.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(ZoneId.of(timezone));
        } catch (DateTimeException e) {
            LOG.warnf("Ignoring unknown time zone '%s' from core-service", timezone);
            return Optional.empty();
        }
    }
}
