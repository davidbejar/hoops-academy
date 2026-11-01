package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import com.hoopsacademy.core.domain.shared.Require;
import java.time.Instant;
import java.util.Objects;

/** An issue opened when an assignment became invalid; resolved exactly once. */
public record EligibilityCase(EligibilityCaseId id, PlayerId player, TeamPlayerId assignment, EligibilityReason reason,
        CaseStatus status, Instant openedAt, Instant resolvedAt, PersonId resolvedBy, CaseResolution resolution,
        String resolutionNote) {

    public static final String NOT_OPEN = "ELIGIBILITY_CASE_NOT_OPEN";
    private static final int MAX_NOTE = 500;

    public EligibilityCase {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(player, "player");
        Objects.requireNonNull(assignment, "assignment");
        Objects.requireNonNull(reason, "reason");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(openedAt, "openedAt");
    }

    public static EligibilityCase open(PlayerId player, TeamPlayerId assignment, EligibilityReason reason, Instant now) {
        return new EligibilityCase(EligibilityCaseId.random(), player, assignment, reason, CaseStatus.OPEN, now, null,
                null, null, null);
    }

    public boolean isOpen() {
        return status == CaseStatus.OPEN;
    }

    public EligibilityCase resolve(CaseResolution how, PersonId by, String note, Instant now) {
        if (!isOpen()) {
            throw new ConflictException("Only an OPEN eligibility case can be resolved", NOT_OPEN);
        }
        String cleanNote = note == null || note.isBlank() ? null : Require.text(note, "note", MAX_NOTE);
        return new EligibilityCase(id, player, assignment, reason, CaseStatus.RESOLVED, openedAt, now, by,
                Objects.requireNonNull(how, "resolution"), cleanNote);
    }
}
