package com.hoopsacademy.core.domain.approvals;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.shared.Require;
import java.time.Instant;
import java.util.Objects;

/**
 * A request to add or withdraw a player. PENDING until an ADMIN approves/rejects it or its requester cancels it;
 * every decision is final. An ADMIN's own action is recorded as an already APPROVED audit row. Immutable; the
 * {@code version} is the optimistic-lock token owned by the persistence adapter.
 */
public record ApprovalRequest(ApprovalRequestId id, ApprovalAction action, PlayerId player, ApprovalPayload payload,
        PersonId requestedBy, ApprovalStatus status, PersonId decidedBy, Instant decidedAt, String decisionNote,
        Instant createdAt) {

    public static final String NOT_PENDING = "NOT_PENDING";
    private static final int MAX_NOTE = 500;

    public ApprovalRequest {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(action, "action");
        Objects.requireNonNull(player, "player");
        Objects.requireNonNull(payload, "payload");
        Objects.requireNonNull(requestedBy, "requestedBy");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(createdAt, "createdAt");
    }

    public static ApprovalRequest pending(ApprovalAction action, PlayerId player, ApprovalPayload payload,
            PersonId requestedBy, Instant now) {
        return new ApprovalRequest(ApprovalRequestId.random(), action, player, payload, requestedBy,
                ApprovalStatus.PENDING, null, null, null, now);
    }

    /** The audit row of an action an ADMIN performed directly: decided by the requester at once. */
    public static ApprovalRequest autoApproved(ApprovalAction action, PlayerId player, ApprovalPayload payload,
            PersonId admin, Instant now) {
        return new ApprovalRequest(ApprovalRequestId.random(), action, player, payload, admin, ApprovalStatus.APPROVED,
                admin, now, null, now);
    }

    public boolean isPending() {
        return status == ApprovalStatus.PENDING;
    }

    public ApprovalRequest approve(PersonId by, String note, Instant now) {
        return decide(ApprovalStatus.APPROVED, by, note, now);
    }

    public ApprovalRequest reject(PersonId by, String note, Instant now) {
        return decide(ApprovalStatus.REJECTED, by, note, now);
    }

    /** @throws AccessDeniedException unless {@code by} is the requester */
    public ApprovalRequest cancel(PersonId by, Instant now) {
        requirePending();
        if (!requestedBy.equals(by)) {
            throw new AccessDeniedException("Only the requester may cancel a request");
        }
        return decide(ApprovalStatus.CANCELLED, by, null, now);
    }

    private ApprovalRequest decide(ApprovalStatus outcome, PersonId by, String note, Instant now) {
        requirePending();
        String cleanNote = note == null || note.isBlank() ? null : Require.text(note, "note", MAX_NOTE);
        return new ApprovalRequest(id, action, player, payload, requestedBy, outcome, Objects.requireNonNull(by, "by"),
                now, cleanNote, createdAt);
    }

    private void requirePending() {
        if (!isPending()) {
            throw new ConflictException("Only a PENDING request can be decided (this one is " + status + ")", NOT_PENDING);
        }
    }
}
