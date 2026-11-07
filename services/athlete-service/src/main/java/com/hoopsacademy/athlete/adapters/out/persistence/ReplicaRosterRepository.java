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
        if (!tenantActive(tenant)) {
            throw new NotFoundException("Team not found");
        }
        List<?> rows = em.createNativeQuery(
                        "select name, season_end_date from athlete.team_ref where tenant_id = :tenant and id = :team")
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
                         where tenant_id = :tenant and id in (:ids) and birth_date is not null and gender is not null""")
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

    private boolean tenantActive(TenantId tenant) {
        return !em.createNativeQuery(
                        "select 1 from athlete.tenant_ref where tenant_id = :tenant and status = 'ACTIVE'")
                .setParameter("tenant", tenant.value()).getResultList().isEmpty();
    }

    private List<TeamRoster.RosterPlayer> rosterPlayers(TenantId tenant, TeamId team) {
        List<?> rows = em.createNativeQuery("""
                        select p.id, p.display_name
                          from athlete.team_player_ref a
                          join athlete.player_ref p on p.tenant_id = a.tenant_id and p.id = a.player_id
                         where a.tenant_id = :tenant and a.team_id = :team
                           and a.left_on is null and a.invalid_reason is null
                           and p.birth_date is not null and p.gender is not null
                         order by a.joined_on, a.id""")
                .setParameter("tenant", tenant.value()).setParameter("team", team.value())
                .getResultList();
        return rows.stream().map(Object[].class::cast)
                .map(columns -> new TeamRoster.RosterPlayer(new PlayerId(ReplicaRows.uuid(columns[0])), (String) columns[1]))
                .toList();
    }

    private List<PersonId> staff(TenantId tenant, TeamId team) {
        List<?> rows = em.createNativeQuery("""
                        select person_id from athlete.team_staff_ref
                         where tenant_id = :tenant and team_id = :team and not removed
                         order by role, since, person_id""")
                .setParameter("tenant", tenant.value()).setParameter("team", team.value())
                .getResultList();
        return rows.stream().map(ReplicaRows::uuid).map(PersonId::new).toList();
    }
}
