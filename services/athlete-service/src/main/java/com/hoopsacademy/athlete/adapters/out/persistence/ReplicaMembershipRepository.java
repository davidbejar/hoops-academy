package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.replica.ReplicaMembershipReads;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.Collection;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * The membership reads of the replica resolver, each one query in the caller's transaction (bound tenant, RLS: the
 * bound tenant's rows are the only ones visible; the tenant row itself is also matched on the requested tenant).
 */
@ApplicationScoped
class ReplicaMembershipRepository implements ReplicaMembershipReads {

    private final EntityManager em;

    ReplicaMembershipRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Optional<TenantState> tenant(TenantId tenant) {
        return first(em.createNativeQuery("select status, timezone from athlete.tenant_ref where tenant_id = :tenant")
                .setParameter("tenant", tenant.value()))
                .map(columns -> new TenantState((String) columns[0], ZoneId.of((String) columns[1])));
    }

    @Override
    public Optional<Member> activeMemberWithLogin(String subject) {
        return first(em.createNativeQuery("""
                        select id, array_to_string(roles, ',') from athlete.person_ref
                         where subject = :subject and active order by id limit 1""")
                .setParameter("subject", subject))
                .map(columns -> new Member(new PersonId(ReplicaRows.uuid(columns[0])), roles((String) columns[1])));
    }

    @Override
    public Optional<PlayerId> playerOf(PersonId person) {
        return ids("select id from athlete.player_ref where person_id = :person order by id limit 1", person.value(),
                PlayerId::new).stream().findFirst();
    }

    @Override
    public Set<PlayerId> guardedPlayers(PersonId guardian) {
        return Set.copyOf(ids("select player_id from athlete.guardian_link_ref where guardian_person_id = :person "
                + "and not removed", guardian.value(), PlayerId::new));
    }

    @Override
    public Set<TeamId> staffTeams(PersonId person) {
        return Set.copyOf(ids("select team_id from athlete.team_staff_ref where person_id = :person and not removed",
                person.value(), TeamId::new));
    }

    @Override
    public Set<TeamId> openValidTeamsOf(Collection<PlayerId> players) {
        if (players.isEmpty()) {
            return Set.of();
        }
        List<?> rows = em.createNativeQuery("""
                        select distinct team_id from athlete.team_player_ref
                         where player_id in (:players) and left_on is null and invalid_reason is null""")
                .setParameter("players", players.stream().map(PlayerId::value).toList()).getResultList();
        return rows.stream().map(ReplicaRows::uuid).map(TeamId::new).collect(Collectors.toSet());
    }

    @Override
    public Set<TeamId> seasonNotEnded(Collection<TeamId> teams, LocalDate today) {
        if (teams.isEmpty()) {
            return Set.of();
        }
        List<?> rows = em.createNativeQuery(
                        "select id from athlete.team_ref where id in (:teams) and season_end_date >= cast(:today as date)")
                .setParameter("teams", teams.stream().map(TeamId::value).toList())
                .setParameter("today", today.toString()).getResultList();
        return rows.stream().map(ReplicaRows::uuid).map(TeamId::new).collect(Collectors.toSet());
    }

    private static Optional<Object[]> first(Query query) {
        List<?> rows = query.getResultList();
        return rows.stream().findFirst().map(Object[].class::cast);
    }

    private <T> List<T> ids(String sql, UUID person, Function<UUID, T> type) {
        List<?> rows = em.createNativeQuery(sql).setParameter("person", person).getResultList();
        return rows.stream().map(ReplicaRows::uuid).map(type).toList();
    }

    private static Set<TenantRole> roles(String csv) {
        Set<TenantRole> roles = EnumSet.noneOf(TenantRole.class);
        Arrays.stream(csv.split(",")).filter(role -> !role.isBlank()).map(TenantRole::valueOf).forEach(roles::add);
        return roles;
    }
}
