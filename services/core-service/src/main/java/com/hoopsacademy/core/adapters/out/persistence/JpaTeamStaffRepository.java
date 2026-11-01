package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaTeamStaffRepository implements TeamStaffRepository {

    private final EntityManager em;

    JpaTeamStaffRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public List<TeamStaffMember> ofTeam(TeamId team) {
        return em.createQuery("select s from TeamStaffEntity s where s.teamId = :team order by s.role, s.since, s.personId",
                        TeamStaffEntity.class)
                .setParameter("team", team.value()).getResultStream().map(JpaTeamStaffRepository::toDomain).toList();
    }

    @Override
    public Optional<TeamStaffMember> find(TeamId team, PersonId person) {
        return Optional.ofNullable(row(team, person)).map(JpaTeamStaffRepository::toDomain);
    }

    @Override
    public void save(TeamStaffMember member) {
        TeamStaffEntity existing = row(member.team(), member.person());
        TeamStaffEntity row = existing != null ? existing : new TeamStaffEntity();
        row.teamId = member.team().value();
        row.personId = member.person().value();
        row.role = member.role().name();
        row.since = member.since();
        if (existing == null) {
            em.persist(row);
        }
    }

    @Override
    public void delete(TeamId team, PersonId person) {
        em.createQuery("delete from TeamStaffEntity s where s.teamId = :team and s.personId = :person")
                .setParameter("team", team.value()).setParameter("person", person.value()).executeUpdate();
    }

    @Override
    public Set<TeamId> teamsOf(PersonId person) {
        return em.createQuery("select s.teamId from TeamStaffEntity s where s.personId = :person", UUID.class)
                .setParameter("person", person.value()).getResultStream().map(TeamId::new).collect(Collectors.toSet());
    }

    private TeamStaffEntity row(TeamId team, PersonId person) {
        return em.createQuery("select s from TeamStaffEntity s where s.teamId = :team and s.personId = :person",
                        TeamStaffEntity.class)
                .setParameter("team", team.value()).setParameter("person", person.value())
                .getResultStream().findFirst().orElse(null);
    }

    private static TeamStaffMember toDomain(TeamStaffEntity row) {
        return new TeamStaffMember(new TeamId(row.teamId), new PersonId(row.personId), StaffRole.valueOf(row.role),
                row.since);
    }
}
