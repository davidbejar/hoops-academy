package com.hoopsacademy.core.domain.approvals;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class ApprovalRequestTest {

    private static final Instant T0 = Instant.parse("2026-11-02T10:00:00Z");
    private static final Instant T1 = Instant.parse("2026-11-02T11:00:00Z");

    private final PersonId coach = PersonId.random();
    private final PersonId admin = PersonId.random();
    private final PlayerId player = PlayerId.random();
    private final ApprovalPayload payload = new ApprovalPayload(TeamId.random(), JerseyNumber.of("7"), "pls", null);
    private final ApprovalRequest pending = ApprovalRequest.pending(ApprovalAction.ADD_PLAYER, player, payload, coach, T0);

    @Test
    void aNewRequestIsPendingAndUndecided() {
        assertThat(pending.status()).isEqualTo(ApprovalStatus.PENDING);
        assertThat(pending.isPending()).isTrue();
        assertThat(pending.decidedBy()).isNull();
        assertThat(pending.decidedAt()).isNull();
        assertThat(pending.requestedBy()).isEqualTo(coach);
        assertThat(pending.createdAt()).isEqualTo(T0);
        assertThat(pending.payload()).isEqualTo(payload);
    }

    @Test
    void anAdminsOwnActionIsAnAutoApprovedAuditRow() {
        ApprovalRequest audit = ApprovalRequest.autoApproved(ApprovalAction.WITHDRAW_PLAYER, player,
                ApprovalPayload.reason("moved"), admin, T0);
        assertThat(audit.status()).isEqualTo(ApprovalStatus.APPROVED);
        assertThat(audit.decidedBy()).isEqualTo(admin);
        assertThat(audit.decidedAt()).isEqualTo(T0);
        assertThat(audit.payload().reason()).isEqualTo("moved");
    }

    @Test
    void approveAndRejectRecordTheDecision() {
        ApprovalRequest approved = pending.approve(admin, "ok", T1);
        assertThat(approved.status()).isEqualTo(ApprovalStatus.APPROVED);
        assertThat(approved.decidedBy()).isEqualTo(admin);
        assertThat(approved.decidedAt()).isEqualTo(T1);
        assertThat(approved.decisionNote()).isEqualTo("ok");
        ApprovalRequest rejected = pending.reject(admin, "no", T1);
        assertThat(rejected.status()).isEqualTo(ApprovalStatus.REJECTED);
        assertThat(rejected.decisionNote()).isEqualTo("no");
        assertThat(pending.approve(admin, "  ", T1).decisionNote()).isNull();
    }

    @Test
    void onlyThePendingStateCanBeDecided() {
        ApprovalRequest approved = pending.approve(admin, null, T1);
        for (ApprovalRequest decided : new ApprovalRequest[] {approved, pending.reject(admin, "n", T1),
                pending.cancel(coach, T1)}) {
            assertThatThrownBy(() -> decided.approve(admin, null, T1)).isInstanceOf(ConflictException.class)
                    .extracting("code").isEqualTo(ApprovalRequest.NOT_PENDING);
            assertThatThrownBy(() -> decided.reject(admin, "n", T1)).isInstanceOf(ConflictException.class);
            assertThatThrownBy(() -> decided.cancel(coach, T1)).isInstanceOf(ConflictException.class);
            // the state is checked before the requester: a decided request is a conflict for everybody
            assertThatThrownBy(() -> decided.cancel(admin, T1)).isInstanceOf(ConflictException.class);
        }
    }

    @Test
    void onlyTheRequesterCancels() {
        ApprovalRequest cancelled = pending.cancel(coach, T1);
        assertThat(cancelled.status()).isEqualTo(ApprovalStatus.CANCELLED);
        assertThat(cancelled.decidedBy()).isEqualTo(coach);
        assertThatThrownBy(() -> pending.cancel(admin, T1)).isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void theNoteIsLimitedTo500Characters() {
        assertThatThrownBy(() -> pending.reject(admin, "x".repeat(501), T1))
                .isInstanceOf(com.hoopsacademy.common.problem.DomainRuleViolation.class);
    }
}
