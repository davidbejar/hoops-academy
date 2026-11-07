package com.hoopsacademy.core.domain.signup;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class AcademyRequestTest {

    private static final Instant REQUESTED = Instant.parse("2026-11-07T10:00:00Z");
    private static final Instant DECIDED = Instant.parse("2026-11-08T09:30:00Z");
    private static final Instant MAILED = Instant.parse("2026-11-08T09:30:02Z");
    private static final TenantId TENANT = TenantId.random();

    private static AcademyRequest pending() {
        return AcademyRequest.submit(AcademyRequestId.random(),
                Requester.of("Ana Ruiz", "ana@example.com", RequesterRole.COACH, AppLocale.ES),
                AcademyName.of("Norte Basket"), REQUESTED);
    }

    @Test
    void aSubmittedRequestIsPendingAndUndecided() {
        AcademyRequest request = pending();

        assertThat(request.status()).isEqualTo(AcademyRequestStatus.PENDING);
        assertThat(request.isPending()).isTrue();
        assertThat(request.requestedAt()).isEqualTo(REQUESTED);
        assertThat(request.decidedAt()).isNull();
        assertThat(request.decidedBy()).isNull();
        assertThat(request.reason()).isNull();
        assertThat(request.tenantId()).isNull();
        assertThat(request.notifiedAt()).isNull();
    }

    @Test
    void acceptingRecordsTheAcademyTheDeciderAndTheTime() {
        AcademyRequest pending = pending();
        AcademyRequest accepted = pending.accept(TENANT, "super-sub", DECIDED);

        assertThat(accepted.status()).isEqualTo(AcademyRequestStatus.ACCEPTED);
        assertThat(accepted.isPending()).isFalse();
        assertThat(accepted.tenantId()).isEqualTo(TENANT);
        assertThat(accepted.decidedBy()).isEqualTo("super-sub");
        assertThat(accepted.decidedAt()).isEqualTo(DECIDED);
        assertThat(accepted.reason()).isNull();
        assertThat(accepted).usingRecursiveComparison()
                .comparingOnlyFields("id", "requester", "academyName", "requestedAt").isEqualTo(pending);
    }

    @Test
    void rejectingRecordsTheTrimmedReasonTheDeciderAndTheTime() {
        AcademyRequest pending = pending();
        AcademyRequest rejected = pending.reject("  Not a basketball academy.\nSorry. ", "super-sub", DECIDED);

        assertThat(rejected.status()).isEqualTo(AcademyRequestStatus.REJECTED);
        assertThat(rejected.reason()).isEqualTo("Not a basketball academy.\nSorry.");
        assertThat(rejected.decidedBy()).isEqualTo("super-sub");
        assertThat(rejected.decidedAt()).isEqualTo(DECIDED);
        assertThat(rejected.tenantId()).isNull();
        assertThat(rejected).usingRecursiveComparison()
                .comparingOnlyFields("id", "requester", "academyName", "requestedAt").isEqualTo(pending);
    }

    @Test
    void theReasonIsRequiredAndAtMost500Characters() {
        assertThat(pending().reject("r".repeat(500), "s", DECIDED).reason()).hasSize(500);
        assertThatThrownBy(() -> pending().reject("r".repeat(501), "s", DECIDED))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_REASON");
        assertThatThrownBy(() -> pending().reject("  ", "s", DECIDED))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_REASON");
    }

    @Test
    void onlyAPendingRequestCanBeDecided() {
        AcademyRequest accepted = pending().accept(TENANT, "s", DECIDED);
        AcademyRequest rejected = pending().reject("no", "s", DECIDED);

        for (AcademyRequest decided : new AcademyRequest[] {accepted, rejected}) {
            assertThatThrownBy(() -> decided.accept(TENANT, "s", DECIDED)).isInstanceOf(ConflictException.class)
                    .hasFieldOrPropertyWithValue("code", "REQUEST_NOT_PENDING");
            assertThatThrownBy(() -> decided.reject("no", "s", DECIDED)).isInstanceOf(ConflictException.class)
                    .hasFieldOrPropertyWithValue("code", "REQUEST_NOT_PENDING");
        }
    }

    @Test
    void aDecisionNeedsTheDeciderAndForAnAcceptanceTheAcademy() {
        assertThatThrownBy(() -> pending().accept(null, "s", DECIDED)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> pending().accept(TENANT, null, DECIDED)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> pending().reject("no", null, DECIDED)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> pending().accept(TENANT, "s", null)).isInstanceOf(NullPointerException.class);
    }

    @Test
    void aDecidedRequestRecordsWhenItsEmailWentOut() {
        AcademyRequest notified = pending().reject("no", "s", DECIDED).notified(MAILED);

        assertThat(notified.notifiedAt()).isEqualTo(MAILED);
        assertThat(notified.status()).isEqualTo(AcademyRequestStatus.REJECTED);
        assertThat(notified.reason()).isEqualTo("no");
        assertThat(pending().accept(TENANT, "s", DECIDED).notified(MAILED).tenantId()).isEqualTo(TENANT);
    }

    @Test
    void aPendingRequestHasNoEmailToRecord() {
        assertThatThrownBy(() -> pending().notified(MAILED)).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void theRecordRejectsInconsistentStates() {
        AcademyRequest p = pending();
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.ACCEPTED, p.requester(),
                p.academyName(), REQUESTED, DECIDED, "s", null, null, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.REJECTED, p.requester(),
                p.academyName(), REQUESTED, DECIDED, "s", null, null, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.PENDING, p.requester(),
                p.academyName(), REQUESTED, DECIDED, null, null, null, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.ACCEPTED, p.requester(),
                p.academyName(), REQUESTED, null, "s", null, TENANT, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.REJECTED, p.requester(),
                p.academyName(), REQUESTED, DECIDED, "s", "no", TENANT, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.PENDING, p.requester(),
                p.academyName(), REQUESTED, null, null, null, null, MAILED))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.ACCEPTED, p.requester(),
                p.academyName(), REQUESTED, DECIDED, null, null, TENANT, null))
                .as("a decision without its decider").isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(p.id(), AcademyRequestStatus.REJECTED, p.requester(),
                p.academyName(), REQUESTED, null, "s", "no", null, null))
                .as("a decision without its time").isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AcademyRequest(null, AcademyRequestStatus.PENDING, p.requester(),
                p.academyName(), REQUESTED, null, null, null, null, null))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    void storedStatesAreRebuiltAsTheyWere() {
        AcademyRequest p = pending();
        AcademyRequest stored = new AcademyRequest(p.id(), AcademyRequestStatus.ACCEPTED, p.requester(),
                p.academyName(), REQUESTED, DECIDED, "s", null, TENANT, MAILED);

        assertThat(stored.notifiedAt()).isEqualTo(MAILED);
        assertThat(stored.tenantId()).isEqualTo(TENANT);
    }

    @Test
    void requestIdsAreRandomAndNotNull() {
        assertThat(AcademyRequestId.random()).isNotEqualTo(AcademyRequestId.random());
        java.util.UUID value = java.util.UUID.randomUUID();
        assertThat(new AcademyRequestId(value)).hasToString(value.toString());
        assertThatThrownBy(() -> new AcademyRequestId(null)).isInstanceOf(NullPointerException.class);
    }
}
