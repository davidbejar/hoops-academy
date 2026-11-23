package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.PlayerBrief;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Typed;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * {@link RosterPort} over the local replica (hoops.roster.source=replica, ADR-0037): answers what core's
 * {@code /internal} API answers (InternalRoster): a tenant that is not ACTIVE or unknown is not found, only open and
 * valid assignments are on a roster, players without birth date or gender are left out. Runs in the request's (or
 * job's) transaction, bound to its tenant, and filters on the tenant argument as well.
 */
@ApplicationScoped
@Typed(ReplicaRosterRepository.class)
public class ReplicaRosterRepository implements RosterPort {

    private final EntityManager em;

    ReplicaRosterRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    @Transactional
    public TeamRoster teamRoster(TenantId tenant, TeamId team) {
        List<?> rows = em.createNativeQuery(
                        """
                        select t.name, t.season_end_date from athlete.team_ref t
                          join athlete.tenant_ref r on r.tenant_id = t.tenant_id and r.status = 'ACTIVE' and not r.removed
                         where t.tenant_id = :tenant and t.id = :team and not t.removed""")
                .setParameter("tenant", tenant.value()).setParameter("team", team.value()).getResultList();
        Object[] row = rows.stream().map(Object[].class::cast).findFirst()
                .orElseThrow(() -> new NotFoundException("Team not found"));
        return new TeamRoster(team, (String) row[0], rosterPlayers(tenant, team), staff(tenant, team),
                ReplicaRows.date(row[1]));
    }

    @Override
    @Transactional
    public Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids) {
        if (ids.isEmpty() || !tenantActive(tenant)) {
            return Map.of();
        }
        List<?> rows = em.createNativeQuery("""
                        select id, display_name, status, birth_date, gender from athlete.player_ref
                         where tenant_id = :tenant and id in (:ids) and birth_date is not null and gender is not null
                           and not removed""")
                .setParameter("tenant", tenant.value())
                .setParameter("ids", ids.stream().map(PlayerId::value).distinct().toList())
                .getResultList();
        Map<PlayerId, PlayerBrief> found = new HashMap<>();
        for (Object row : rows) {
            Object[] columns = (Object[]) row;
            PlayerId id = new PlayerId(ReplicaRows.uuid(columns[0]));
            found.put(id, new PlayerBrief(id, (String) columns[1], (String) columns[2],
                    Optional.of(ReplicaRows.date(columns[3])), Optional.of(Gender.valueOf((String) columns[4]))));
        }
        return found;
    }

    /** One query: the open, valid assignments of complete players, on known teams of an ACTIVE tenant (as rosters). */
    @Override
    @Transactional
    public Set<TeamId> teamsOf(TenantId tenant, Collection<PlayerId> players, Collection<TeamId> candidates) {
        if (players.isEmpty() || candidates.isEmpty()) {
            return Set.of();
        }
        List<?> rows = em.createNativeQuery("""
                        select distinct a.team_id
                          from athlete.team_player_ref a
                          join athlete.player_ref p on p.tenant_id = a.tenant_id and p.id = a.player_id
                          join athlete.team_ref t on t.tenant_id = a.tenant_id and t.id = a.team_id
                          join athlete.tenant_ref r on r.tenant_id = a.tenant_id
                         where a.tenant_id = :tenant and a.player_id in (:players) and a.team_id in (:teams)
                           and a.left_on is null and a.invalid_reason is null and not a.removed
                           and p.birth_date is not null and p.gender is not null and not p.removed
                           and not t.removed and r.status = 'ACTIVE' and not r.removed""")
                .setParameter("tenant", tenant.value())
                .setParameter("players", players.stream().map(PlayerId::value).distinct().toList())
                .setParameter("teams", candidates.stream().map(TeamId::value).distinct().toList())
                .getResultList();
        return rows.stream().map(ReplicaRows::uuid).map(TeamId::new).collect(Collectors.toSet());
    }

    private boolean tenantActive(TenantId tenant) {
        return !em.createNativeQuery(
                        "select 1 from athlete.tenant_ref where tenant_id = :tenant and status = 'ACTIVE' and not removed")
                .setParameter("tenant", tenant.value()).getResultList().isEmpty();
    }

    private List<TeamRoster.RosterPlayer> rosterPlayers(TenantId tenant, TeamId team) {
        List<?> rows = em.createNativeQuery("""
                        select p.id, p.display_name
                          from athlete.team_player_ref a
                          join athlete.player_ref p on p.tenant_id = a.tenant_id and p.id = a.player_id
                         where a.tenant_id = :tenant and a.team_id = :team
                           and a.left_on is null and a.invalid_reason is null and not a.removed
                           and p.birth_date is not null and p.gender is not null and not p.removed
                         order by a.joined_on, a.id""")
                .setParameter("tenant", tenant.value()).setParameter("team", team.value())
                .getResultList();
        return rows.stream().map(Object[].class::cast)
                .map(columns -> new TeamRoster.RosterPlayer(new PlayerId(ReplicaRows.uuid(columns[0])), (String) columns[1]))
                .toList();
    }

    private List<PersonId> staff(TenantId tenant, TeamId team) {
        List<?> rows = em.createNativeQuery("""
                        select s.person_id from athlete.team_staff_ref s
                         where s.tenant_id = :tenant and s.team_id = :team and not s.removed
                           and not exists (select 1 from athlete.person_ref p
                                            where p.tenant_id = s.tenant_id and p.id = s.person_id and p.removed)
                         order by s.role, s.since, s.person_id""")
                .setParameter("tenant", tenant.value()).setParameter("team", team.value())
                .getResultList();
        return rows.stream().map(ReplicaRows::uuid).map(PersonId::new).toList();
    }
}
