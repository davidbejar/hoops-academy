package com.hoopsacademy.common.client;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.hoopsacademy.common.client.CoreInternalClient.PlayerBriefDto;
import com.hoopsacademy.common.client.CoreInternalClient.TeamRosterDto;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.WebApplicationException;
import java.time.DateTimeException;
import java.time.Duration;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

/**
 * Cached access to core's {@code /internal} API shared by game and athlete (ADR-0008 v1: synchronous REST). Answers
 * are cached for {@code hoops.core.cache-ttl} (default 30 s) per distinct arguments; players one by one. Failures,
 * unknown teams and "not a member" are never cached. A 404 from core is a {@link NotFoundException} (or an empty
 * membership); a timeout, connection failure or any other status is an {@link UpstreamUnavailableException} (503).
 * Services wrap it in their own {@code RosterPort} adapter to map to their domain types.
 */
@ApplicationScoped
public class CoreRosterClient {

    private static final Logger LOG = Logger.getLogger(CoreRosterClient.class);

    private record TeamKey(TenantId tenant, UUID team) {}

    private record MemberKey(TenantId tenant, String subject) {}

    private record PlayerKey(TenantId tenant, UUID player) {}

    private final CoreInternalClient core;
    private final Cache<TeamKey, TeamRosterDto> rosters;
    private final Cache<MemberKey, CoreMembership> members;
    private final Cache<PlayerKey, PlayerBriefDto> players;

    @Inject
    CoreRosterClient(@RestClient CoreInternalClient core,
            @ConfigProperty(name = "hoops.core.cache-ttl", defaultValue = "30S") Duration ttl) {
        this.core = core;
        this.rosters = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(2_000).build();
        this.members = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(10_000).build();
        this.players = Caffeine.newBuilder().expireAfterWrite(ttl).maximumSize(20_000).build();
    }

    /** @throws NotFoundException when core does not know the team in the tenant */
    public TeamRosterDto teamRoster(TenantId tenant, UUID team) {
        return rosters.get(new TeamKey(tenant, team),
                key -> call("team roster", () -> core.teamRoster(team, tenant.toString())));
    }

    /** Players found by id; unknown ids (and anything core sends that was not asked for) are absent. */
    public Map<UUID, PlayerBriefDto> players(TenantId tenant, Collection<UUID> ids) {
        Map<UUID, PlayerBriefDto> found = new HashMap<>();
        List<UUID> missing = new ArrayList<>();
        for (UUID id : new LinkedHashSet<>(ids)) {
            PlayerBriefDto cached = players.getIfPresent(new PlayerKey(tenant, id));
            if (cached != null) {
                found.put(id, cached);
            } else {
                missing.add(id);
            }
        }
        if (!missing.isEmpty()) {
            List<UUID> asked = missing.stream().sorted().toList();
            var response = call("players", () -> core.players(tenant.toString(),
                    new CoreInternalClient.PlayerBatchRequestDto(asked)));
            for (PlayerBriefDto dto : Objects.requireNonNullElse(response.players(), List.<PlayerBriefDto>of())) {
                if (missing.contains(dto.id())) {
                    players.put(new PlayerKey(tenant, dto.id()), dto);
                    found.put(dto.id(), dto);
                }
            }
        }
        return found;
    }

    /** The subject's membership (any tenant status), or empty when core says they are not a member. */
    public Optional<CoreMembership> membership(TenantId tenant, String subject) {
        MemberKey key = new MemberKey(tenant, subject);
        CoreMembership cached = members.getIfPresent(key);
        if (cached != null) {
            return Optional.of(cached);
        }
        try {
            CoreMembership fresh = toMembership(tenant, call("authz context", () -> core.authz(tenant.toString(), subject)));
            members.put(key, fresh);
            return Optional.of(fresh);
        } catch (NotFoundException notAMember) {
            return Optional.empty();
        }
    }

    /** Drops every cached answer (tests, or an operator hook when a membership change must apply at once). */
    public void clearCache() {
        rosters.invalidateAll();
        members.invalidateAll();
        players.invalidateAll();
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
            throw new UpstreamUnavailableException("core-service answered " + status + " for " + what, e);
        } catch (RuntimeException e) {
            LOG.warnf("core-service call for %s failed: %s", what, e.toString());
            throw new UpstreamUnavailableException("core-service is not reachable for " + what, e);
        }
    }

    private static CoreMembership toMembership(TenantId tenant, CoreInternalClient.AuthzContextDto dto) {
        Set<TenantRole> roles = EnumSet.noneOf(TenantRole.class);
        Objects.requireNonNullElse(dto.roles(), List.<String>of()).forEach(role -> roles.add(TenantRole.valueOf(role)));
        AuthzContext context = new AuthzContext(dto.sub(), dto.personId(), tenant, roles, set(dto.staffTeamIds()),
                set(dto.linkedPlayerIds()), Optional.ofNullable(dto.ownPlayerId()), set(dto.playerTeamIds()),
                zoneOf(dto.timezone()));
        return new CoreMembership(context, CoreMembership.TenantStatus.valueOf(dto.tenantStatus()));
    }

    private static Set<UUID> set(List<UUID> ids) {
        return ids == null ? Set.of() : Set.copyOf(ids);
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
