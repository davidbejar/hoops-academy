package com.hoopsacademy.game.adapters.out.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.game.application.ProjectionRepository;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.projection.MatchSummary;
import com.hoopsacademy.game.domain.projection.PeriodScore;
import com.hoopsacademy.game.domain.projection.PlayerLine;
import com.hoopsacademy.game.domain.projection.Projection;
import com.hoopsacademy.game.domain.projection.ProjectionWarning;
import com.hoopsacademy.game.domain.projection.SeasonLine;
import com.hoopsacademy.game.domain.projection.StatLine;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** {@code game.match_player_stats} and {@code game.match_summary} via JDBC; JSON columns hold warnings and period scores. */
@ApplicationScoped
class JpaProjectionRepository extends JdbcRepository implements ProjectionRepository {

    private static final String STAT_COLUMNS = """
            pts, fgm1, fga1, fgm2, fga2, fgm3, fga3, ast, oreb, dreb, tov, stl, blk, pf, technical_fouls,
            unsportsmanlike_fouls, seconds_played""";

    /** JSON shape of a stored warning. */
    record WarningJson(String code, UUID eventId, UUID playerId, String message) {}

    private record SummaryRow(MatchSummary summary, List<ProjectionWarning> warnings) {}

    private final EntityManager em;
    private final ObjectMapper json;

    JpaProjectionRepository(EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = json;
    }

    @Override
    EntityManager entityManager() {
        return em;
    }

    @Override
    public void save(MatchId matchId, Projection projection) {
        UUID match = matchId.value();
        update("delete from game.match_player_stats where match_id = ?", s -> s.setObject(1, match));
        batch("insert into game.match_player_stats (match_id, tenant_id, player_id, was_starter, warnings, " + STAT_COLUMNS
                        + ") values (?, app.current_tenant(), ?, ?, cast(? as jsonb), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                projection.playerStats().stream().<Binder>map(line -> s -> {
                    s.setObject(1, match);
                    s.setObject(2, line.playerId().value());
                    s.setBoolean(3, line.wasStarter());
                    s.setString(4, write(line.warnings().stream().map(JpaProjectionRepository::toJson).toList()));
                    bindStats(s, 5, line.stats());
                }).toList());
        MatchSummary summary = projection.summary();
        update("""
                insert into game.match_summary (match_id, tenant_id, our_score, opp_score, period_scores, warnings, last_server_seq)
                values (?, app.current_tenant(), ?, ?, cast(? as jsonb), cast(? as jsonb), ?)
                on conflict (match_id) do update
                   set our_score = excluded.our_score, opp_score = excluded.opp_score,
                       period_scores = excluded.period_scores, warnings = excluded.warnings,
                       last_server_seq = excluded.last_server_seq, updated_at = now()""", s -> {
            s.setObject(1, match);
            s.setInt(2, summary.teamScore());
            s.setInt(3, summary.opponentScore());
            s.setString(4, write(summary.periodScores()));
            s.setString(5, write(projection.warnings().stream().map(JpaProjectionRepository::toJson).toList()));
            s.setLong(6, summary.lastServerSeq());
        });
    }

    @Override
    public Optional<Projection> find(MatchId matchId) {
        List<SummaryRow> summaries = query("""
                select our_score, opp_score, period_scores::text as period_scores, warnings::text as warnings, last_server_seq
                  from game.match_summary where match_id = ?""", s -> s.setObject(1, matchId.value()), row -> new SummaryRow(
                new MatchSummary(row.getInt("our_score"), row.getInt("opp_score"),
                        read(row.getString("period_scores"), new TypeReference<List<PeriodScore>>() {}),
                        row.getLong("last_server_seq")),
                warnings(row.getString("warnings"))));
        if (summaries.isEmpty()) {
            return Optional.empty();
        }
        List<PlayerLine> lines = query("select player_id, was_starter, warnings::text as warnings, " + STAT_COLUMNS
                        + " from game.match_player_stats where match_id = ? order by player_id",
                s -> s.setObject(1, matchId.value()),
                row -> new PlayerLine(PlayerId.of(uuid(row, "player_id")), row.getBoolean("was_starter"), stats(row),
                        warnings(row.getString("warnings"))));
        SummaryRow summary = summaries.get(0);
        return Optional.of(new Projection(lines, summary.summary(), summary.warnings(), Map.of()));
    }

    @Override
    public List<SeasonLine> seasonLines(PlayerId playerId, SeasonId seasonId) {
        return query("select m.id as match_id, m.scheduled_at, m.opponent_name, m.status, s.was_starter, " + STAT_COLUMNS + """
                  from game.match_player_stats s join game.match m on m.id = s.match_id
                 where s.player_id = ? and m.season_id = ? and m.status in ('LIVE', 'FINISHED')
                 order by m.scheduled_at, m.id""", s -> {
            s.setObject(1, playerId.value());
            s.setObject(2, seasonId.value());
        }, row -> new SeasonLine(MatchId.of(uuid(row, "match_id")), instant(row, "scheduled_at"),
                row.getString("opponent_name"), MatchStatus.valueOf(row.getString("status")),
                row.getBoolean("was_starter"), stats(row)));
    }

    private static void bindStats(PreparedStatement s, int from, StatLine l) throws SQLException {
        int[] values = {l.points(), l.fg1Made(), l.fg1Attempted(), l.fg2Made(), l.fg2Attempted(), l.fg3Made(),
                l.fg3Attempted(), l.assists(), l.offensiveRebounds(), l.defensiveRebounds(), l.turnovers(), l.steals(),
                l.blocks(), l.personalFouls(), l.technicalFouls(), l.unsportsmanlikeFouls(), l.secondsPlayed()};
        for (int i = 0; i < values.length; i++) {
            s.setInt(from + i, values[i]);
        }
    }

    private static StatLine stats(ResultSet r) throws SQLException {
        return new StatLine(r.getInt("pts"), r.getInt("fgm1"), r.getInt("fga1"), r.getInt("fgm2"), r.getInt("fga2"),
                r.getInt("fgm3"), r.getInt("fga3"), r.getInt("ast"), r.getInt("oreb"), r.getInt("dreb"), r.getInt("tov"),
                r.getInt("stl"), r.getInt("blk"), r.getInt("pf"), r.getInt("technical_fouls"),
                r.getInt("unsportsmanlike_fouls"), r.getInt("seconds_played"));
    }

    private static WarningJson toJson(ProjectionWarning w) {
        return new WarningJson(w.code(), w.eventId().value(), w.playerId() == null ? null : w.playerId().value(), w.message());
    }

    private List<ProjectionWarning> warnings(String text) {
        return read(text, new TypeReference<List<WarningJson>>() {}).stream()
                .map(w -> new ProjectionWarning(w.code(), EventId.of(w.eventId()),
                        w.playerId() == null ? null : PlayerId.of(w.playerId()), w.message()))
                .toList();
    }

    private String write(Object value) {
        try {
            return json.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Projection cannot be written as JSON", e);
        }
    }

    private <T> T read(String text, TypeReference<T> type) {
        try {
            return json.readValue(text, type);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored projection is not valid JSON", e);
        }
    }
}
