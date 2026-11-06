package com.hoopsacademy.game.adapters.out.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.game.adapters.json.MatchEventJson;
import com.hoopsacademy.game.application.MatchEventRepository;
import com.hoopsacademy.game.application.Recorder;
import com.hoopsacademy.game.application.StoredEvent;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.OptionalLong;
import java.util.UUID;

/** {@code game.match_event} (and the {@code sync_receipt} bookkeeping) via JDBC. */
@ApplicationScoped
class JpaMatchEventRepository extends JdbcRepository implements MatchEventRepository {

    private static final String COLUMNS = """
            id, server_seq, device_id, client_seq, type, player_id, period, clock_seconds_remaining, payload::text as payload,
            recorded_by_person_id, recorded_by_display_name, recorded_at_client, received_at, voided_by""";

    /**
     * The feed of a filtered viewer in one statement, the SQL form of {@code EventVisibility} (ADR-0030; checked against
     * it by {@code FeedVisibilityQueryPropertyTest}). An event with a player is visible when that player is, one without
     * is team-level. A VOID follows its target through VOID-of-VOID chains ({@code chain}: the VOIDs of the page range,
     * each with the target still to resolve and the VOIDs passed); it is hidden only when the chain ends in an event of
     * this match about a hidden player, so an unknown target (or one in another match) and a cycle leave it visible.
     * VOID targets may lie before {@code after}, so they are looked up by id in the whole match.
     */
    private static final String VISIBLE_AFTER = """
            with recursive feed as (
                select cast(? as uuid) as match_id, cast(? as bigint) as after_seq, cast(? as uuid[]) as players
            ), chain (origin, target, passed) as (
                select e.id, cast(e.payload->>'targetEventId' as uuid), array[e.id]
                  from game.match_event e, feed f
                 where e.match_id = f.match_id and e.server_seq > f.after_seq and e.type = 'VOID'
                union all
                select c.origin, cast(t.payload->>'targetEventId' as uuid), c.passed || t.id
                  from chain c
                  join game.match_event t on t.id = c.target
                  join feed f on t.match_id = f.match_id
                 where t.type = 'VOID' and t.id <> all(c.passed)
            ), hidden_void as (
                select c.origin
                  from chain c
                  join game.match_event t on t.id = c.target
                  join feed f on t.match_id = f.match_id
                 where t.type <> 'VOID' and t.player_id is not null and t.player_id <> all(f.players)
            )
            select %s
              from game.match_event e, feed f
             where e.match_id = f.match_id and e.server_seq > f.after_seq
               and case when e.type = 'VOID' then not exists (select 1 from hidden_void h where h.origin = e.id)
                        else e.player_id is null or e.player_id = any(f.players) end
             order by e.server_seq
             limit ?""".formatted(COLUMNS);

    private final EntityManager em;
    private final ObjectMapper json;

    JpaMatchEventRepository(EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = json;
    }

    @Override
    EntityManager entityManager() {
        return em;
    }

    @Override
    public List<StoredEvent> findByMatch(MatchId matchId) {
        return query("select " + COLUMNS + " from game.match_event where match_id = ? order by server_seq",
                s -> s.setObject(1, matchId.value()), this::toStored);
    }

    @Override
    public List<StoredEvent> after(MatchId matchId, PlayerVisibility viewer, long after, int limit) {
        if (viewer.seesAll()) {
            return query("select " + COLUMNS + " from game.match_event where match_id = ? and server_seq > ? order by server_seq limit ?",
                    s -> {
                        s.setObject(1, matchId.value());
                        s.setLong(2, after);
                        s.setInt(3, limit);
                    }, this::toStored);
        }
        return query(VISIBLE_AFTER, s -> {
            s.setObject(1, matchId.value());
            s.setLong(2, after);
            s.setArray(3, s.getConnection().createArrayOf("uuid", viewer.players().stream().map(PlayerId::value).toArray()));
            s.setInt(4, limit);
        }, this::toStored);
    }

    @Override
    public long lastServerSeq(MatchId matchId) {
        return query("select coalesce(max(server_seq), 0) from game.match_event where match_id = ?",
                s -> s.setObject(1, matchId.value()), row -> row.getLong(1)).get(0);
    }

    @Override
    public OptionalLong append(MatchId matchId, MatchEvent event, Recorder recorder) {
        List<Long> seq = query("""
                insert into game.match_event (id, tenant_id, match_id, device_id, client_seq, type, player_id, period,
                    clock_seconds_remaining, payload, recorded_by_person_id, recorded_by_display_name, recorded_at_client)
                values (?, app.current_tenant(), ?, ?, ?, ?, ?, ?, ?, cast(? as jsonb), ?, ?, ?)
                on conflict do nothing
                returning server_seq""", s -> {
            s.setObject(1, event.id().value());
            s.setObject(2, matchId.value());
            s.setString(3, event.meta().deviceId());
            s.setLong(4, event.meta().clientSeq());
            s.setString(5, event.type().name());
            setUuid(s, 6, event.playerId().map(p -> p.value()).orElse(null));
            s.setInt(7, event.meta().period());
            s.setInt(8, event.meta().clockSecondsRemaining());
            s.setString(9, payloadText(event));
            s.setObject(10, recorder.personId());
            s.setString(11, recorder.displayName());
            s.setTimestamp(12, Timestamp.from(event.meta().recordedAtClient()));
        }, row -> row.getLong(1));
        return seq.isEmpty() ? OptionalLong.empty() : OptionalLong.of(seq.get(0));
    }

    @Override
    public void markVoided(MatchId matchId, Map<EventId, EventId> voidedBy) {
        update("update game.match_event set voided_by = null where match_id = ? and voided_by is not null",
                s -> s.setObject(1, matchId.value()));
        if (!voidedBy.isEmpty()) {
            batch("update game.match_event set voided_by = ? where match_id = ? and id = ?",
                    voidedBy.entrySet().stream().<Binder>map(e -> s -> {
                        s.setObject(1, e.getValue().value());
                        s.setObject(2, matchId.value());
                        s.setObject(3, e.getKey().value());
                    }).toList());
        }
    }

    @Override
    public void recordReceipt(MatchId matchId, String deviceId, long clientSeq) {
        update("""
                insert into game.sync_receipt (match_id, tenant_id, device_id, last_client_seq)
                values (?, app.current_tenant(), ?, ?)
                on conflict (match_id, device_id) do update
                   set last_client_seq = greatest(game.sync_receipt.last_client_seq, excluded.last_client_seq),
                       updated_at = now()""", s -> {
            s.setObject(1, matchId.value());
            s.setString(2, deviceId);
            s.setLong(3, clientSeq);
        });
    }

    @Override
    public long count() {
        return query("select count(*) from game.match_event", s -> { }, row -> row.getLong(1)).get(0);
    }

    @Override
    public long countReceivedSince(Instant since) {
        return query("select count(*) from game.match_event where received_at >= ?",
                s -> s.setTimestamp(1, Timestamp.from(since)), row -> row.getLong(1)).get(0);
    }

    private String payloadText(MatchEvent event) {
        ObjectNode payload = MatchEventJson.payload(json, event);
        return payload == null ? "{}" : payload.toString();
    }

    private StoredEvent toStored(ResultSet row) throws SQLException {
        ObjectNode node = json.createObjectNode()
                .put("id", uuid(row, "id").toString())
                .put("deviceId", row.getString("device_id"))
                .put("clientSeq", row.getLong("client_seq"))
                .put("type", row.getString("type"))
                .put("period", row.getInt("period"))
                .put("clockSecondsRemaining", row.getInt("clock_seconds_remaining"))
                .put("recordedAtClient", instant(row, "recorded_at_client").toString());
        UUID player = uuid(row, "player_id");
        if (player != null) {
            node.put("playerId", player.toString());
        }
        try {
            node.set("payload", json.readTree(row.getString("payload")));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored payload is not JSON", e);
        }
        RecordedEvent recorded = new RecordedEvent(MatchEventJson.decode(node), row.getLong("server_seq"));
        UUID voidedBy = uuid(row, "voided_by");
        return new StoredEvent(recorded,
                new Recorder(uuid(row, "recorded_by_person_id"), row.getString("recorded_by_display_name")),
                instant(row, "received_at"), voidedBy == null ? null : EventId.of(voidedBy));
    }
}
