package com.hoopsacademy.athlete.domain;

import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/** One concrete training occasion of a team; materialised from a schedule or created ad hoc. */
public record TrainingSession(
        SessionId id,
        TeamId teamId,
        ScheduleId scheduleId,
        Instant startsAt,
        Instant endsAt,
        String location,
        UUID planId,
        SessionStatus status,
        String notes,
        String cancelReason,
        boolean manuallyEdited) {

    public TrainingSession {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(teamId, "teamId");
        Objects.requireNonNull(startsAt, "startsAt");
        Objects.requireNonNull(endsAt, "endsAt");
        Objects.requireNonNull(status, "status");
        if (!endsAt.isAfter(startsAt)) {
            throw new TrainingRuleViolation("A session must end after it starts", "INVALID_TIME_RANGE");
        }
    }

    public static TrainingSession adHoc(TeamId teamId, Instant startsAt, int durationMinutes, String location,
            UUID planId, String notes) {
        return new TrainingSession(SessionId.random(), teamId, null, startsAt,
                startsAt.plus(Duration.ofMinutes(Duration15to480.require(durationMinutes))), location, planId,
                SessionStatus.PLANNED, notes, null, false);
    }

    public static TrainingSession materialised(PlannedSlot slot) {
        return new TrainingSession(SessionId.random(), slot.teamId(), slot.scheduleId(), slot.startsAt(),
                slot.endsAt(), slot.location(), null, SessionStatus.PLANNED, null, null, false);
    }

    public Optional<ScheduleId> schedule() {
        return Optional.ofNullable(scheduleId);
    }

    public int durationMinutes() {
        return (int) Duration.between(startsAt, endsAt).toMinutes();
    }

    public boolean isCancelled() {
        return status == SessionStatus.CANCELLED;
    }

    public TrainingSession cancelled(String reason) {
        if (status != SessionStatus.PLANNED) {
            throw new TrainingStateConflict("Only PLANNED sessions can be cancelled", "SESSION_NOT_PLANNED");
        }
        return new TrainingSession(id, teamId, scheduleId, startsAt, endsAt, location, planId,
                SessionStatus.CANCELLED, notes, reason, manuallyEdited);
    }

    /** @throws TrainingStateConflict {@code SESSION_CANCELLED}: a cancelled session is frozen */
    public void requireChangeable() {
        if (isCancelled()) {
            throw new TrainingStateConflict("A cancelled session cannot be changed", "SESSION_CANCELLED");
        }
    }

    /** The session with another plan (a staff edit, so a re-plan keeps it). */
    public TrainingSession withPlan(UUID newPlanId) {
        return edited(startsAt, durationMinutes(), location, newPlanId, notes, status);
    }

    /** Applies staff edits (every argument is the NEW value); a cancelled session is frozen. */
    public TrainingSession edited(Instant newStart, int newDurationMinutes, String newLocation, UUID newPlanId,
            String newNotes, SessionStatus newStatus) {
        requireChangeable();
        if (newStatus == SessionStatus.CANCELLED) {
            throw new TrainingRuleViolation("Use the cancel operation to cancel a session", "USE_CANCEL");
        }
        return new TrainingSession(id, teamId, scheduleId, newStart,
                newStart.plus(Duration.ofMinutes(Duration15to480.require(newDurationMinutes))), newLocation, newPlanId,
                newStatus, newNotes, null, true);
    }
}
