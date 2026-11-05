package com.hoopsacademy.core.domain.eligibility;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class EligibilityCaseTest {

    private static final Instant OPENED = Instant.parse("2026-11-02T01:00:00Z");
    private final EligibilityCase open = EligibilityCase.open(PlayerId.random(), TeamPlayerId.random(),
            EligibilityReason.CATEGORY_TOO_LOW, OPENED);

    @Test
    void opensAsOpenWithoutResolution() {
        assertThat(open.status()).isEqualTo(CaseStatus.OPEN);
        assertThat(open.openedAt()).isEqualTo(OPENED);
        assertThat(open.resolution()).isNull();
        assertThat(open.isOpen()).isTrue();
    }

    @Test
    void resolvesOnceWithResolverNoteAndTime() {
        PersonId admin = PersonId.random();
        Instant later = OPENED.plusSeconds(60);
        EligibilityCase resolved = open.resolve(CaseResolution.DISMISSED, admin, " ok ", later);
        assertThat(resolved.status()).isEqualTo(CaseStatus.RESOLVED);
        assertThat(resolved.isOpen()).isFalse();
        assertThat(resolved.resolvedBy()).isEqualTo(admin);
        assertThat(resolved.resolvedAt()).isEqualTo(later);
        assertThat(resolved.resolutionNote()).isEqualTo("ok");
        assertThat(open.resolve(CaseResolution.REMOVED_FROM_TEAM, admin, " ", later).resolutionNote()).isNull();
        assertThat(open.resolve(CaseResolution.REMOVED_FROM_TEAM, admin, null, later).resolutionNote()).isNull();
        assertThatThrownBy(() -> resolved.resolve(CaseResolution.DISMISSED, admin, null, later))
                .isInstanceOf(ConflictException.class)
                .extracting(e -> ((ConflictException) e).code()).isEqualTo(EligibilityCase.NOT_OPEN);
        assertThatThrownBy(() -> open.resolve(CaseResolution.DISMISSED, admin, "x".repeat(501), later))
                .isInstanceOf(DomainRuleViolation.class);
    }
}
