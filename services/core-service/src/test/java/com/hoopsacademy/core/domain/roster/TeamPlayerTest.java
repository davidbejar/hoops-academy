package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class TeamPlayerTest {

    private static final LocalDate JOINED = LocalDate.of(2026, 9, 1);
    private final TeamPlayer assignment = TeamPlayer.assign(TeamId.random(), PlayerId.random(), JerseyNumber.of("7"),
            JOINED, 1);

    @Test
    void aNewAssignmentIsOpenAndValid() {
        assertThat(assignment.isOpen()).isTrue();
        assertThat(assignment.isValid()).isTrue();
        assertThat(assignment.playUpLevels()).isEqualTo(1);
        assertThat(assignment.jersey()).isEqualTo(JerseyNumber.of("7"));
        assertThatThrownBy(() -> TeamPlayer.assign(TeamId.random(), PlayerId.random(), null, JOINED, -1))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(TeamPlayer.assign(TeamId.random(), PlayerId.random(), null, JOINED, 0).playUpLevels()).isZero();
    }

    @Test
    void invalidationKeepsTheRowOpenButInvalid() {
        Instant at = Instant.parse("2026-11-02T01:00:00Z");
        TeamPlayer invalid = assignment.invalidate(EligibilityReason.CATEGORY_TOO_LOW, at);
        assertThat(invalid.isOpen()).isTrue();
        assertThat(invalid.isValid()).isFalse();
        assertThat(invalid.invalidatedAt()).isEqualTo(at);
        assertThat(invalid.invalidReason()).isEqualTo(EligibilityReason.CATEGORY_TOO_LOW);
        assertThatThrownBy(() -> invalid.invalidate(EligibilityReason.GENDER_POLICY, at))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void closingSetsLeftOnNeverBeforeJoinedOn() {
        TeamPlayer closed = assignment.close(LocalDate.of(2026, 10, 1));
        assertThat(closed.leftOn()).isEqualTo(LocalDate.of(2026, 10, 1));
        assertThat(closed.isOpen()).isFalse();
        assertThat(closed.isValid()).isFalse();
        assertThat(assignment.close(LocalDate.of(2026, 8, 1)).leftOn()).isEqualTo(JOINED);
        assertThatThrownBy(() -> closed.close(LocalDate.of(2026, 10, 2))).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void jerseyCanBeChangedOrCleared() {
        assertThat(assignment.withJersey(null).jersey()).isNull();
        assertThat(assignment.withJersey(JerseyNumber.of("00")).jersey().value()).isEqualTo("00");
    }

    @Test
    void jerseyNumbersAreOneOrTwoDigits() {
        assertThat(JerseyNumber.ofNullable(null)).isNull();
        assertThat(JerseyNumber.ofNullable("0")).isEqualTo(JerseyNumber.of("0"));
        assertThat(JerseyNumber.of("0")).isNotEqualTo(JerseyNumber.of("00"));
        assertThatThrownBy(() -> JerseyNumber.of(null)).isInstanceOf(DomainRuleViolation.class);
        for (String invalid : new String[] {"", "100", "7a", " 7"}) {
            assertThatThrownBy(() -> JerseyNumber.of(invalid)).isInstanceOf(DomainRuleViolation.class);
        }
    }
}
