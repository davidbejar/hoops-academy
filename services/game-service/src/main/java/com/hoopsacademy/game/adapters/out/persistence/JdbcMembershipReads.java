package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.common.authz.Member;
import com.hoopsacademy.common.authz.MembershipReads;
import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.sql.Array;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * The membership rule's reads (ADR-0066) on the roster replica of V4 (ADR-0037), each one query in the caller's
 * transaction: RLS shows only the bound tenant's rows, and removed rows (WP82) are never read, nor guardian links to a
 * removed player.
 */
@ApplicationScoped
class JdbcMembershipReads extends JdbcRepository implements MembershipReads {

    private final EntityManager em;

    JdbcMembershipReads(EntityManager em) {
        this.em = em;
    }

    @Override
    EntityManager entityManager() {
        return em;
    }

    @Override
    public Optional<TenantState> tenant(TenantId tenant) {
        return first(query("select status, timezone from game.tenant_ref where tenant_id = ? and not removed",
                statement -> statement.setObject(1, tenant.value()),
                row -> new TenantState(TenantStatus.valueOf(row.getString("status")),
                        ZoneId.of(row.getString("timezone")))));
    }

    @Override
    public Optional<Member> activeMember(String subject) {
        return first(query("""
                select id, roles from game.person_ref where subject = ? and active and not removed
                 order by id limit 1""",
                statement -> statement.setString(1, subject),
                row -> new Member(uuid(row, "id"), roles(row.getArray("roles")))));
    }

    @Override
    public Optional<UUID> ownPlayer(UUID personId) {
        return first(query("select id from game.player_ref where person_id = ? and not removed order by id limit 1",
                statement -> statement.setObject(1, personId), row -> uuid(row, "id")));
    }

    @Override
    public Set<UUID> guardedPlayers(UUID personId) {
        return new HashSet<>(query("""
                select l.player_id from game.guardian_link_ref l
                 where l.guardian_person_id = ? and not l.removed
                   and not exists (select 1 from game.player_ref p
                                    where p.tenant_id = l.tenant_id and p.id = l.player_id and p.removed)""",
                statement -> statement.setObject(1, personId), row -> uuid(row, "player_id")));
    }

    @Override
    public Set<UUID> staffTeams(UUID personId) {
        return new HashSet<>(query("select team_id from game.team_staff_ref where person_id = ? and not removed",
                statement -> statement.setObject(1, personId), row -> uuid(row, "team_id")));
    }

    @Override
    public Set<UUID> openValidTeamsOf(Set<UUID> players) {
        return new HashSet<>(query("""
                select team_id from game.team_player_ref
                 where player_id = any (?) and left_on is null and invalid_reason is null and not removed""",
                statement -> statement.setArray(1, uuids(statement, players)), row -> uuid(row, "team_id")));
    }

    @Override
    public Map<UUID, LocalDate> seasonEnds(Set<UUID> teams) {
        return query("""
                select id, season_end_date from game.team_ref
                 where id = any (?) and not removed and season_end_date is not null""",
                statement -> statement.setArray(1, uuids(statement, teams)),
                row -> Map.entry(uuid(row, "id"), row.getObject("season_end_date", LocalDate.class)))
                .stream().collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    private static Set<TenantRole> roles(Array roles) throws SQLException {
        Set<TenantRole> result = EnumSet.noneOf(TenantRole.class);
        for (String role : (String[]) roles.getArray()) {
            result.add(TenantRole.valueOf(role));
        }
        return result;
    }

    private static Array uuids(PreparedStatement statement, Set<UUID> ids) throws SQLException {
        return statement.getConnection().createArrayOf("uuid", ids.toArray());
    }

    private static <T> Optional<T> first(List<T> rows) {
        return rows.stream().findFirst();
    }
}
