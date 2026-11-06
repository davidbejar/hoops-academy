package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.RosterStates;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import java.sql.Date;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Reads the roster states of the event contracts with native SQL, so the values come from the database (after a flush
 * of this transaction's changes) and never from the session cache. Locks: an aggregate whose state spans rows that are
 * written separately takes the lock of the row every such writer of the aggregate holds, so concurrent writers append in
 * commit order and the later one reads the earlier one's committed change (read committed; the read is a statement after
 * the lock): a person's or a player's state locks the person row ({@code FOR UPDATE}: roles and the player status are
 * written without touching it); a team's state takes {@code FOR SHARE} on its season row (season date changes);
 * the tenant's {@code FOR SHARE} on the registry row (the platform's lifecycle changes). Team assignments, staff
 * entries and guardian links are single rows that their writers update or delete (row lock) or insert (new key).
 */
@ApplicationScoped
class JpaRosterStateRepository implements RosterStates {

    private final EntityManager em;

    JpaRosterStateRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Optional<PersonState> person(PersonId id) {
        em.flush();
        if (!lock("select id from core.person where id = :id for update", id.value())) {
            return Optional.empty();
        }
        Object[] row = single("""
                select p.given_name || ' ' || p.family_name, u.keycloak_sub, p.active, pl.id
                  from core.person p
                  left join core.app_user u on u.id = p.user_id
                  left join core.player pl on pl.person_id = p.id
                 where p.id = :id""", id.value()).orElseThrow();
        return Optional.of(new PersonState((String) row[0], Optional.ofNullable((String) row[1]), roles(id),
                (Boolean) row[2], Optional.ofNullable((UUID) row[3]).map(PlayerId::new)));
    }

    @Override
    public Optional<PlayerState> player(PlayerId id) {
        em.flush();
        if (!lock("""
                select p.id from core.person p join core.player pl on pl.person_id = p.id where pl.id = :id
                   for update of p""", id.value())) {
            return Optional.empty();
        }
        return single("""
                select p.id, p.given_name || ' ' || p.family_name, pl.status, p.birth_date, p.gender
                  from core.player pl join core.person p on p.id = pl.person_id
                 where pl.id = :id""", id.value())
                .map(row -> new PlayerState(new PersonId((UUID) row[0]), (String) row[1],
                        PlayerStatus.valueOf((String) row[2]), date(row[3]),
                        Optional.ofNullable((String) row[4]).map(Gender::valueOf)));
    }

    @Override
    public Optional<TeamState> team(TeamId id) {
        em.flush();
        if (!lock("""
                select s.id from core.season s join core.team t on t.season_id = s.id where t.id = :id
                   for share of s""", id.value())) {
            return Optional.empty();
        }
        return single("""
                select t.season_id, s.start_date, s.end_date, t.name, t.alias, t.age_category_id, t.gender_policy
                  from core.team t join core.season s on s.id = t.season_id
                 where t.id = :id""", id.value())
                .map(row -> new TeamState(new SeasonId((UUID) row[0]), date(row[1]).orElseThrow(),
                        date(row[2]).orElseThrow(), (String) row[3], Optional.ofNullable((String) row[4]),
                        new AgeCategoryId((UUID) row[5]), GenderPolicy.valueOf((String) row[6])));
    }

    @Override
    public List<TeamId> teamsOfSeason(SeasonId season) {
        em.flush();
        return uuids("select id from core.team where season_id = :id order by created_at, id", season.value())
                .stream().map(TeamId::new).toList();
    }

    @Override
    public Optional<TeamPlayerState> teamPlayer(TeamPlayerId id) {
        em.flush();
        return single("""
                select team_id, player_id, jersey_number, joined_on, left_on, play_up_levels, invalid_reason
                  from core.team_player where id = :id""", id.value())
                .map(row -> new TeamPlayerState(new TeamId((UUID) row[0]), new PlayerId((UUID) row[1]),
                        Optional.ofNullable((String) row[2]), date(row[3]).orElseThrow(), date(row[4]),
                        ((Number) row[5]).intValue(),
                        Optional.ofNullable((String) row[6]).map(EligibilityReason::valueOf)));
    }

    @Override
    public Optional<TeamStaffState> teamStaff(TeamId team, PersonId person) {
        em.flush();
        return first(em.createNativeQuery("""
                        select role, since from core.team_staff where team_id = :team and person_id = :person""",
                        Object[].class)
                .setParameter("team", team.value()).setParameter("person", person.value()))
                .map(row -> new TeamStaffState(StaffRole.valueOf((String) row[0]), date(row[1]).orElseThrow()));
    }

    @Override
    public Optional<GuardianLinkState> guardianLink(GuardianLinkId id) {
        em.flush();
        return single("select guardian_person_id, player_id from core.guardian_link where id = :id", id.value())
                .map(row -> new GuardianLinkState(new PersonId((UUID) row[0]), new PlayerId((UUID) row[1])));
    }

    @Override
    public Optional<TenantState> tenant() {
        em.flush();
        return first(em.createNativeQuery("""
                        select slug, name, status, timezone, default_locale from core.tenant
                         where id = app.current_tenant() for share""", Object[].class))
                .map(row -> new TenantState((String) row[0], (String) row[1], TenantStatus.valueOf((String) row[2]),
                        ZoneId.of((String) row[3]), AppLocale.fromCode((String) row[4])));
    }

    private Set<TenantRole> roles(PersonId person) {
        Set<TenantRole> roles = EnumSet.noneOf(TenantRole.class);
        em.createNativeQuery("select role from core.membership_role where person_id = :id", String.class)
                .setParameter("id", person.value()).getResultStream()
                .forEach(role -> roles.add(TenantRole.valueOf((String) role)));
        return roles;
    }

    private boolean lock(String sql, UUID id) {
        return !uuids(sql, id).isEmpty();
    }

    @SuppressWarnings("unchecked")
    private List<UUID> uuids(String sql, UUID id) {
        return em.createNativeQuery(sql, UUID.class).setParameter("id", id).getResultList();
    }

    private Optional<Object[]> single(String sql, UUID id) {
        return first(em.createNativeQuery(sql, Object[].class).setParameter("id", id));
    }

    private static Optional<Object[]> first(Query query) {
        return query.getResultList().stream().findFirst().map(row -> (Object[]) row);
    }

    private static Optional<LocalDate> date(Object value) {
        return switch (value) {
            case null -> Optional.empty();
            case LocalDate local -> Optional.of(local);
            case Date sql -> Optional.of(sql.toLocalDate());
            default -> throw new IllegalStateException("Not a date: " + value.getClass());
        };
    }
}
