package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.athlete.application.replica.ReplicaMembershipReads.Member;
import com.hoopsacademy.athlete.application.replica.ReplicaMembershipReads.TenantState;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Typed;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * The tenant filter's membership from the replica (hoops.roster.source=replica), computed like core's
 * {@code MembershipLookup} behind /internal/authz: only an ACTIVE tenant's active person with the login is a member;
 * the own player counts with the PLAYER role, guardian links with PARENT; staff and player teams leave out teams whose
 * season has ended in the tenant's zone. Called with the requested tenant bound, so every read is RLS-scoped.
 */
@ApplicationScoped
@Typed(ReplicaAuthzResolver.class)
public class ReplicaAuthzResolver implements AuthzContextResolver {

    private final ReplicaMembershipReads reads;
    private final Clock clock;

    public ReplicaAuthzResolver(ReplicaMembershipReads reads, Clock clock) {
        this.reads = reads;
        this.clock = clock;
    }

    @Override
    @Transactional
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        Optional<TenantState> tenant = reads.tenant(tenantId).filter(TenantState::active);
        if (tenant.isEmpty()) {
            return Optional.empty();
        }
        return reads.activeMemberWithLogin(subject).map(member -> contextOf(subject, tenantId, member, tenant.get()));
    }

    private AuthzContext contextOf(String subject, TenantId tenantId, Member member, TenantState tenant) {
        Optional<PlayerId> ownPlayer = member.roles().contains(TenantRole.PLAYER)
                ? reads.playerOf(member.personId())
                : Optional.empty();
        Set<PlayerId> linked = member.roles().contains(TenantRole.PARENT)
                ? reads.guardedPlayers(member.personId())
                : Set.of();
        Set<TeamId> staffTeams = reads.staffTeams(member.personId());
        Set<PlayerId> players = new HashSet<>(linked);
        ownPlayer.ifPresent(players::add);
        Set<TeamId> playerTeams = players.isEmpty() ? Set.of() : reads.openValidTeamsOf(players);
        Set<TeamId> candidates = new HashSet<>(staffTeams);
        candidates.addAll(playerTeams);
        Set<TeamId> running = candidates.isEmpty() ? Set.of()
                : reads.seasonNotEnded(candidates, LocalDate.now(clock.withZone(tenant.timezone())));
        return new AuthzContext(subject, member.personId().value(), tenantId, member.roles(),
                teamIds(staffTeams, running), linked.stream().map(PlayerId::value).collect(Collectors.toSet()),
                ownPlayer.map(PlayerId::value), teamIds(playerTeams, running), Optional.of(tenant.timezone()));
    }

    private static Set<UUID> teamIds(Set<TeamId> teams, Set<TeamId> running) {
        return teams.stream().filter(running::contains).map(TeamId::value).collect(Collectors.toSet());
    }
}
