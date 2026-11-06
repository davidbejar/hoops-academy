package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.events.EventTopic;
import com.hoopsacademy.core.application.events.RosterChange;
import com.hoopsacademy.core.application.port.RosterInventory;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** The bound tenant's roster rows and outbox, as core_app (RLS: that tenant only). Ids only, no state. */
@ApplicationScoped
class JpaRosterInventoryRepository implements RosterInventory {

    private final EntityManager em;

    JpaRosterInventoryRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public List<RosterChange> live(EventTopic topic) {
        return switch (topic) {
            case PERSON -> ids("select id from core.person order by id").stream()
                    .<RosterChange>map(id -> new RosterChange.Person(new PersonId(id))).toList();
            case PLAYER -> ids("select id from core.player order by id").stream()
                    .<RosterChange>map(id -> new RosterChange.Player(new PlayerId(id))).toList();
            case TEAM -> ids("select id from core.team order by id").stream()
                    .<RosterChange>map(id -> new RosterChange.Team(new TeamId(id))).toList();
            case TEAM_PLAYER -> ids("select id from core.team_player order by id").stream()
                    .<RosterChange>map(id -> new RosterChange.TeamPlayer(new TeamPlayerId(id))).toList();
            case TEAM_STAFF -> rows("select team_id, person_id from core.team_staff order by team_id, person_id")
                    .stream().<RosterChange>map(row -> new RosterChange.TeamStaff(new TeamId((UUID) row[0]),
                            new PersonId((UUID) row[1]))).toList();
            case GUARDIAN_LINK -> rows("select id, guardian_person_id, player_id from core.guardian_link order by id")
                    .stream().<RosterChange>map(row -> new RosterChange.GuardianLink(new GuardianLinkId((UUID) row[0]),
                            new PersonId((UUID) row[1]), new PlayerId((UUID) row[2]))).toList();
            case TENANT -> ids("select id from core.tenant where id = app.current_tenant()").stream()
                    .<RosterChange>map(id -> new RosterChange.Tenant()).toList();
        };
    }

    @Override
    @SuppressWarnings("unchecked")
    public Set<String> withEvents(EventTopic topic, long afterSeq) {
        return new HashSet<>(em.createNativeQuery(
                        "select distinct aggregate_id from core.outbox where topic = :topic and seq > :after", String.class)
                .setParameter("topic", topic.topic()).setParameter("after", afterSeq).getResultList());
    }

    @Override
    public long lastSeq() {
        return ((Number) em.createNativeQuery("select coalesce(max(seq), 0) from core.outbox").getSingleResult())
                .longValue();
    }

    @SuppressWarnings("unchecked")
    private List<UUID> ids(String sql) {
        return em.createNativeQuery(sql, UUID.class).getResultList();
    }

    @SuppressWarnings("unchecked")
    private List<Object[]> rows(String sql) {
        return em.createNativeQuery(sql, Object[].class).getResultList();
    }
}
