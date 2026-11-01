package com.hoopsacademy.game.support;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.game.application.MatchEventRepository;
import com.hoopsacademy.game.application.MatchReprojection;
import com.hoopsacademy.game.application.MatchRepository;
import com.hoopsacademy.game.application.Recorder;
import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchRoster;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Test data written straight through the repository inside a tenant scope (bypasses the REST authz). */
@ApplicationScoped
public class MatchSeed {

    private final TenantScope tenantScope;
    private final MatchRepository matches;
    private final MatchEventRepository events;
    private final MatchReprojection reprojection;

    public MatchSeed(TenantScope tenantScope, MatchRepository matches, MatchEventRepository events,
            MatchReprojection reprojection) {
        this.tenantScope = tenantScope;
        this.matches = matches;
        this.events = events;
        this.reprojection = reprojection;
    }

    /** Persists a match of {@code season} with the given roster (it needs a starter for LIVE and FINISHED). */
    public UUID match(String tenant, String team, String season, MatchStatus status, Instant scheduledAt,
            List<RosterEntry> entries) {
        MatchId id = MatchId.random();
        tenantScope.runAs(TenantId.parse(tenant), () -> {
            Match match = Match.schedule(id, TeamId.of(UUID.fromString(team)), SeasonId.of(UUID.fromString(season)),
                    "Rivals " + scheduledAt, HomeAway.AWAY, scheduledAt, null, null, null, UUID.randomUUID());
            MatchRoster roster = new MatchRoster(id, entries);
            moveTo(match, status, roster);
            matches.save(match);
            matches.replaceRoster(roster);
        });
        return id.value();
    }

    /** Stores events directly (no authz) as {@code recordedBy} and re-projects the match. */
    public void events(String tenant, UUID matchId, UUID recordedBy, List<RecordedEvent> recorded) {
        tenantScope.runAs(TenantId.parse(tenant), () -> {
            MatchId id = MatchId.of(matchId);
            recorded.forEach(e -> events.append(id, e.event(), new Recorder(recordedBy, "Seeder")));
            reprojection.reproject(matches.findById(id).orElseThrow());
        });
    }

    private static void moveTo(Match match, MatchStatus status, MatchRoster roster) {
        Instant now = Instant.parse("2026-12-01T11:00:00Z");
        if (status == MatchStatus.LIVE || status == MatchStatus.FINISHED) {
            match.start(roster, now);
        }
        if (status == MatchStatus.FINISHED) {
            match.finish(now);
        }
        if (status == MatchStatus.CANCELLED) {
            match.cancel("seeded", now);
        }
    }

    public UUID match(String tenant, String team, MatchStatus status) {
        return match(tenant, team, status, Instant.parse("2026-12-01T10:00:00Z"));
    }

    /** Persists a match in {@code status}; LIVE and FINISHED ones get a starter first. */
    public UUID match(String tenant, String team, MatchStatus status, Instant scheduledAt) {
        MatchId id = MatchId.random();
        tenantScope.runAs(TenantId.parse(tenant), () -> {
            Match match = Match.schedule(id, TeamId.of(UUID.fromString(team)), SeasonId.of(UUID.randomUUID()), "Seeded FC",
                    HomeAway.HOME, scheduledAt, null, null, null, UUID.randomUUID());
            Instant now = Instant.parse("2026-12-01T11:00:00Z");
            MatchRoster roster = new MatchRoster(id,
                    List.of(new RosterEntry(PlayerId.of(UUID.randomUUID()), "Seed Starter", new JerseyNumber("5"), true)));
            if (status == MatchStatus.LIVE || status == MatchStatus.FINISHED) {
                match.start(roster, now);
            }
            if (status == MatchStatus.FINISHED) {
                match.finish(now);
            }
            if (status == MatchStatus.CANCELLED) {
                match.cancel("seeded", now);
            }
            matches.save(match);
            matches.replaceRoster(roster);
        });
        return id.value();
    }
}
