package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.game.application.replica.EventEnvelope;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.application.replica.RosterEvent.GuardianLinkChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.GuardianLinkRemoved;
import com.hoopsacademy.game.application.replica.RosterEvent.PersonChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.PlayerChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamPlayerChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamStaffChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamStaffRemoved;
import com.hoopsacademy.game.application.replica.RosterEvent.TenantChanged;
import com.hoopsacademy.game.application.replica.RosterReplica;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * The roster replica tables of V4 (ADR-0037), written with {@code app.current_tenant()} as tenant (the event's tenant,
 * bound by the caller). Every upsert is guarded: the stored row is replaced only by an event that is not older
 * ({@code occurred_at <= excluded.occurred_at}).
 */
@ApplicationScoped
class JdbcRosterReplicaRepository extends JdbcRepository implements RosterReplica {

    /** One parameter value of an upsert, bound in column order. */
    @FunctionalInterface
    private interface Value {
        void bind(PreparedStatement statement, int index) throws SQLException;
    }

    /** A guarded upsert statement; {@code hasId} false for the tenant's own row (keyed by tenant only). */
    private record Upsert(String sql, boolean hasId) {}

    private static final Upsert TENANT_REF = upsert("game.tenant_ref", false, "status", "timezone");
    private static final Upsert PERSON_REF = upsert("game.person_ref", true, "display_name", "subject", "roles", "active");
    private static final Upsert PLAYER_REF =
            upsert("game.player_ref", true, "person_id", "display_name", "status", "birth_date", "gender");
    private static final Upsert TEAM_REF = upsert("game.team_ref", true, "season_id", "season_end_date", "name");
    private static final Upsert TEAM_PLAYER_REF = upsert("game.team_player_ref", true, "team_id", "player_id",
            "jersey_number", "joined_on", "left_on", "invalid_reason");
    private static final Upsert TEAM_STAFF_REF =
            upsert("game.team_staff_ref", true, "team_id", "person_id", "role", "removed");
    private static final Upsert GUARDIAN_LINK_REF =
            upsert("game.guardian_link_ref", true, "guardian_person_id", "player_id", "removed");

    private final EntityManager em;

    JdbcRosterReplicaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    EntityManager entityManager() {
        return em;
    }

    @Override
    public boolean markApplied(EventEnvelope envelope, String topic) {
        return update("""
                insert into game.applied_event (tenant_id, event_id, topic) values (app.current_tenant(), ?, ?)
                on conflict do nothing""", statement -> {
            statement.setObject(1, envelope.eventId());
            statement.setString(2, topic);
        }) == 1;
    }

    @Override
    public boolean save(RosterEvent event) {
        return switch (event) {
            case TenantChanged tenant -> upsertRow(TENANT_REF, tenant.envelope(),
                    text(tenant.status().name()), text(tenant.timezone().getId()));
            case PersonChanged person -> upsertRow(PERSON_REF, person.envelope(), text(person.displayName()),
                    text(person.subject().orElse(null)), roles(person), flag(person.active()));
            case PlayerChanged player -> upsertRow(PLAYER_REF, player.envelope(), object(player.personId()),
                    text(player.displayName()), text(player.status()), object(player.birthDate().orElse(null)),
                    text(player.gender().orElse(null)));
            case TeamChanged team -> upsertRow(TEAM_REF, team.envelope(), object(team.seasonId().value()),
                    object(team.seasonEndDate()), text(team.name()));
            case TeamPlayerChanged assignment -> upsertRow(TEAM_PLAYER_REF, assignment.envelope(),
                    object(assignment.teamId().value()), object(assignment.playerId().value()),
                    text(assignment.jerseyNumber().orElse(null)), object(assignment.joinedOn()),
                    object(assignment.leftOn().orElse(null)), text(assignment.invalidReason().orElse(null)));
            case TeamStaffChanged staff -> upsertRow(TEAM_STAFF_REF, staff.envelope(),
                    object(staff.teamId().value()), object(staff.personId()), text(staff.role()), flag(false));
            case TeamStaffRemoved staff -> upsertRow(TEAM_STAFF_REF, staff.envelope(),
                    object(staff.teamId().value()), object(staff.personId()), text(null), flag(true));
            case GuardianLinkChanged link -> upsertRow(GUARDIAN_LINK_REF, link.envelope(),
                    object(link.guardianPersonId()), object(link.playerId().value()), flag(false));
            case GuardianLinkRemoved link -> upsertRow(GUARDIAN_LINK_REF, link.envelope(),
                    object(link.guardianPersonId()), object(link.playerId().value()), flag(true));
        };
    }

    /**
     * {@code insert ... on conflict do update ... where stored.occurred_at <= excluded.occurred_at} for one row: the
     * tenant (always {@code app.current_tenant()}), the aggregate id when the table has one, the columns, then
     * {@code occurred_at} and {@code event_id}.
     */
    private static Upsert upsert(String table, boolean hasId, String... columns) {
        List<String> all = new ArrayList<>();
        all.add("tenant_id");
        if (hasId) {
            all.add("id");
        }
        all.addAll(Arrays.asList(columns));
        all.add("occurred_at");
        all.add("event_id");
        String placeholders = all.stream().map(c -> c.equals("tenant_id") ? "app.current_tenant()" : "?")
                .collect(Collectors.joining(", "));
        String key = hasId ? "tenant_id, id" : "tenant_id";
        String assignments = all.stream().skip(hasId ? 2 : 1).map(c -> c + " = excluded." + c)
                .collect(Collectors.joining(", "));
        return new Upsert("insert into " + table + " (" + String.join(", ", all) + ") values (" + placeholders + ")"
                + " on conflict (" + key + ") do update set " + assignments
                + " where " + table + ".occurred_at <= excluded.occurred_at", hasId);
    }

    private boolean upsertRow(Upsert upsert, EventEnvelope envelope, Value... columns) {
        return update(upsert.sql(), statement -> {
            int index = 1;
            if (upsert.hasId()) {
                statement.setObject(index++, envelope.aggregateId());
            }
            for (Value column : columns) {
                column.bind(statement, index++);
            }
            statement.setObject(index++, OffsetDateTime.ofInstant(envelope.occurredAt(), ZoneOffset.UTC));
            statement.setObject(index, envelope.eventId());
        }) == 1;
    }

    private static Value text(String value) {
        return (statement, index) -> statement.setString(index, value);
    }

    private static Value object(Object value) {
        return (statement, index) -> statement.setObject(index, value);
    }

    private static Value flag(boolean value) {
        return (statement, index) -> statement.setBoolean(index, value);
    }

    private static Value roles(PersonChanged person) {
        return (statement, index) -> statement.setArray(index, statement.getConnection().createArrayOf("text",
                person.roles().stream().map(Enum::name).sorted().toArray()));
    }
}
