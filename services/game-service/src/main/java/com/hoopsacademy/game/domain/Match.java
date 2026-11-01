package com.hoopsacademy.game.domain;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * The match aggregate and its state machine: SCHEDULED, then LIVE, then FINISHED; CANCELLED from SCHEDULED or LIVE.
 * Illegal transitions raise {@link ConflictException} (409). Time is passed in, never read from a clock here.
 */
public final class Match {

    public static final int DEFAULT_PERIOD_COUNT = 4;
    public static final int DEFAULT_PERIOD_MINUTES = 10;

    private final MatchId id;
    private final TeamId teamId;
    private final SeasonId seasonId;
    private final UUID createdByPersonId;
    private final long version;
    private String opponentName;
    private HomeAway homeAway;
    private Instant scheduledAt;
    private String venue;
    private MatchStatus status;
    private int periodCount;
    private int periodMinutes;
    private Instant startedAt;
    private Instant finishedAt;
    private Instant cancelledAt;
    private String cancelReason;
    private MatchScore score = MatchScore.NONE;

    private Match(MatchId id, TeamId teamId, SeasonId seasonId, UUID createdByPersonId, long version) {
        this.id = Objects.requireNonNull(id, "id");
        this.teamId = Objects.requireNonNull(teamId, "teamId");
        this.seasonId = Objects.requireNonNull(seasonId, "seasonId");
        this.createdByPersonId = Objects.requireNonNull(createdByPersonId, "createdByPersonId");
        this.version = version;
    }

    /** Schedules a new match; null period settings fall back to the defaults (4 x 10 minutes). */
    public static Match schedule(
            MatchId id, TeamId teamId, SeasonId seasonId, String opponentName, HomeAway homeAway, Instant scheduledAt,
            String venue, Integer periodCount, Integer periodMinutes, UUID createdByPersonId) {
        Match match = new Match(id, teamId, seasonId, createdByPersonId, 0);
        match.opponentName = requireOpponent(opponentName);
        match.homeAway = Objects.requireNonNull(homeAway, "homeAway");
        match.scheduledAt = Objects.requireNonNull(scheduledAt, "scheduledAt");
        match.venue = venue;
        match.periodCount = requireRange(periodCount == null ? DEFAULT_PERIOD_COUNT : periodCount, 1, 8, "periodCount");
        match.periodMinutes =
                requireRange(periodMinutes == null ? DEFAULT_PERIOD_MINUTES : periodMinutes, 1, 60, "periodMinutes");
        match.status = MatchStatus.SCHEDULED;
        return match;
    }

    /** Rebuilds a stored match with its projected score (persistence adapter only). */
    public static Match restore(
            MatchId id, TeamId teamId, SeasonId seasonId, String opponentName, HomeAway homeAway, Instant scheduledAt,
            String venue, MatchStatus status, int periodCount, int periodMinutes, Instant startedAt, Instant finishedAt,
            Instant cancelledAt, String cancelReason, UUID createdByPersonId, long version, MatchScore score) {
        Match match = new Match(id, teamId, seasonId, createdByPersonId, version);
        match.score = Objects.requireNonNull(score, "score");
        match.opponentName = opponentName;
        match.homeAway = homeAway;
        match.scheduledAt = scheduledAt;
        match.venue = venue;
        match.status = status;
        match.periodCount = periodCount;
        match.periodMinutes = periodMinutes;
        match.startedAt = startedAt;
        match.finishedAt = finishedAt;
        match.cancelledAt = cancelledAt;
        match.cancelReason = cancelReason;
        return match;
    }

    /**
     * SCHEDULED to LIVE; a LIVE match stays LIVE (idempotent). Needs at least one starter on the roster.
     *
     * @throws ConflictException from FINISHED or CANCELLED
     * @throws DomainRuleViolation (NO_STARTERS) when the roster has no starter
     */
    public void start(MatchRoster roster, Instant now) {
        if (status == MatchStatus.LIVE) {
            return;
        }
        requireStatus(MatchStatus.SCHEDULED, "start");
        if (!roster.hasStarter()) {
            throw new DomainRuleViolation("A match needs at least one starter before it can start", "NO_STARTERS");
        }
        status = MatchStatus.LIVE;
        startedAt = now;
    }

    /** LIVE to FINISHED. */
    public void finish(Instant now) {
        requireStatus(MatchStatus.LIVE, "finish");
        status = MatchStatus.FINISHED;
        finishedAt = now;
    }

    /** SCHEDULED or LIVE to CANCELLED. */
    public void cancel(String reason, Instant now) {
        if (!status.isOpen()) {
            throw new ConflictException("A " + status + " match cannot be cancelled", "INVALID_STATE");
        }
        if (reason == null || reason.isBlank()) {
            throw new DomainRuleViolation("A cancellation needs a reason", "REASON_REQUIRED");
        }
        status = MatchStatus.CANCELLED;
        cancelledAt = now;
        cancelReason = reason;
    }

    /** Whether the roster may still be replaced. */
    public void requireRosterEditable() {
        if (!status.isOpen()) {
            throw new ConflictException("The roster of a " + status + " match cannot be changed", "INVALID_STATE");
        }
    }

    /**
     * Changes descriptive fields (null = unchanged). Period settings only while SCHEDULED; nothing once the match
     * is FINISHED or CANCELLED.
     */
    public void update(
            String newOpponentName, HomeAway newHomeAway, Instant newScheduledAt, boolean venueGiven, String newVenue,
            Integer newPeriodCount, Integer newPeriodMinutes) {
        if (!status.isOpen()) {
            throw new ConflictException("A " + status + " match cannot be edited", "INVALID_STATE");
        }
        boolean changesPeriods = newPeriodCount != null || newPeriodMinutes != null;
        if (changesPeriods && status != MatchStatus.SCHEDULED) {
            throw new ConflictException("Period settings can only change while SCHEDULED", "INVALID_STATE");
        }
        if (newOpponentName != null) {
            opponentName = requireOpponent(newOpponentName);
        }
        if (newHomeAway != null) {
            homeAway = newHomeAway;
        }
        if (newScheduledAt != null) {
            scheduledAt = newScheduledAt;
        }
        if (venueGiven) {
            venue = newVenue;
        }
        if (newPeriodCount != null) {
            periodCount = requireRange(newPeriodCount, 1, 8, "periodCount");
        }
        if (newPeriodMinutes != null) {
            periodMinutes = requireRange(newPeriodMinutes, 1, 60, "periodMinutes");
        }
    }

    private void requireStatus(MatchStatus expected, String action) {
        if (status != expected) {
            throw new ConflictException("Cannot " + action + " a " + status + " match", "INVALID_STATE");
        }
    }

    private static String requireOpponent(String name) {
        if (name == null || name.isBlank() || name.length() > 120) {
            throw new DomainRuleViolation("Opponent name must be 1 to 120 characters", "INVALID_OPPONENT_NAME");
        }
        return name;
    }

    private static int requireRange(int value, int min, int max, String field) {
        if (value < min || value > max) {
            throw new DomainRuleViolation(field + " must be between " + min + " and " + max, "INVALID_" + field.toUpperCase());
        }
        return value;
    }

    public MatchId id() { return id; }
    public TeamId teamId() { return teamId; }
    public SeasonId seasonId() { return seasonId; }
    public String opponentName() { return opponentName; }
    public HomeAway homeAway() { return homeAway; }
    public Instant scheduledAt() { return scheduledAt; }
    public String venue() { return venue; }
    public MatchStatus status() { return status; }
    public int periodCount() { return periodCount; }
    public int periodMinutes() { return periodMinutes; }
    public Instant startedAt() { return startedAt; }
    public Instant finishedAt() { return finishedAt; }
    public Instant cancelledAt() { return cancelledAt; }
    public String cancelReason() { return cancelReason; }
    public UUID createdByPersonId() { return createdByPersonId; }
    public long version() { return version; }
    public MatchScore score() { return score; }
}
