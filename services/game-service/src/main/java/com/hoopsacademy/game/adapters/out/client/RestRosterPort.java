package com.hoopsacademy.game.adapters.out.client;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.application.MemberAccess;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.RosterPort;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.application.UpstreamUnavailableException;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.WebApplicationException;
import java.time.Duration;
import java.util.Collection;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

/**
 * {@link RosterPort} over core-service's internal REST API (ADR-0008). Each call is cached for
 * {@code hoops.roster.cache-ttl} (30 s) per distinct arguments; failures are never cached. A 404 means "unknown
 * team / tenant" ({@link NotFoundException}); every other failure (timeout, connection, 5xx, 401/403) becomes
 * {@link UpstreamUnavailableException} (503, UPSTREAM_UNAVAILABLE).
 */
@ApplicationScoped
public class RestRosterPort implements RosterPort {

    private static final Logger LOG = Logger.getLogger(RestRosterPort.class);
    private static final int MAX_CACHE_ENTRIES = 10_000;

    private final CoreInternalClient core;
    private final Cache<String, Object> cache;

    RestRosterPort(
            @RestClient CoreInternalClient core,
            @ConfigProperty(name = "hoops.roster.cache-ttl", defaultValue = "30S") Duration ttl) {
        this.core = core;
        this.cache = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(MAX_CACHE_ENTRIES).build();
    }

    @Override
    public TeamRoster teamRoster(TenantId tenantId, TeamId teamId) {
        return cached("team|" + tenantId + "|" + teamId, () -> {
            CoreInternalClient.TeamRosterDto dto = call("team roster", () -> core.teamRoster(teamId.value(), tenantId.toString()));
            return new TeamRoster(TeamId.of(dto.teamId()), SeasonId.of(dto.seasonId()), dto.teamName(),
                    dto.players().stream()
                            .map(p -> new TeamRoster.Player(PlayerId.of(p.playerId()), p.displayName(), p.jerseyNumber()))
                            .toList());
        });
    }

    @Override
    public List<PlayerBrief> players(TenantId tenantId, Collection<PlayerId> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        List<UUID> sorted = ids.stream().map(PlayerId::value).distinct().sorted().toList();
        return cached("players|" + tenantId + "|" + sorted, () -> {
            CoreInternalClient.PlayerBatchDto dto = call("players",
                    () -> core.players(tenantId.toString(), new CoreInternalClient.PlayerBatchRequestDto(sorted)));
            return dto.players().stream().map(p -> new PlayerBrief(PlayerId.of(p.id()), p.displayName())).toList();
        });
    }

    @Override
    public Optional<MemberAccess> authzContext(TenantId tenantId, String sub) {
        return cached("authz|" + tenantId + "|" + sub, () -> {
            try {
                return Optional.of(toAccess(call("authz context", () -> core.authz(tenantId.toString(), sub))));
            } catch (NotFoundException notAMember) {
                return Optional.<MemberAccess>empty();
            }
        });
    }

    /** Drops every cached answer (tests, or an operator hook if a membership change must apply at once). */
    public void clearCache() {
        cache.invalidateAll();
    }

    @SuppressWarnings("unchecked")
    private <T> T cached(String key, Supplier<T> loader) {
        return (T) cache.get(key, k -> loader.get());
    }

    private static <T> T call(String what, Supplier<T> request) {
        try {
            return request.get();
        } catch (WebApplicationException e) {
            int status = e.getResponse().getStatus();
            if (status == 404) {
                throw new NotFoundException("core-service does not know this " + what + " resource");
            }
            LOG.warnf("core-service answered %d for %s", status, what);
            throw new UpstreamUnavailableException("core-service answered " + status, e);
        } catch (RuntimeException e) {
            LOG.warnf("core-service call for %s failed: %s", what, e.toString());
            throw new UpstreamUnavailableException("core-service is not reachable", e);
        }
    }

    private static MemberAccess toAccess(CoreInternalClient.AuthzDto dto) {
        Set<TenantRole> roles = EnumSet.noneOf(TenantRole.class);
        dto.roles().forEach(role -> roles.add(TenantRole.valueOf(role)));
        return new MemberAccess(dto.sub(), dto.personId(), MemberAccess.TenantStatus.valueOf(dto.tenantStatus()), roles,
                new HashSet<>(dto.staffTeamIds()), new HashSet<>(dto.linkedPlayerIds()), Optional.ofNullable(dto.ownPlayerId()));
    }
}
