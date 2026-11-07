package com.hoopsacademy.common.problem;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.security.DenialKind;
import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.RollbackException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Path;
import java.util.LinkedHashSet;
import java.util.Set;
import org.hibernate.StaleStateException;
import org.junit.jupiter.api.Test;

/** The decisions of {@link ProblemExceptionMappers} without a container (PIT scope, WP88). */
class ProblemMappingTest {

    @Test
    void aLostVersionRaceIsRecognisedDirectlyAndWrapped() {
        assertThat(ProblemMapping.causedByConcurrentModification(new OptimisticLockException())).isTrue();
        assertThat(ProblemMapping.causedByConcurrentModification(new StaleStateException("stale"))).isTrue();
        assertThat(ProblemMapping.causedByConcurrentModification(
                new IllegalStateException(new RollbackException(new StaleStateException("at commit"))))).isTrue();
    }

    @Test
    void anyOtherFailureIsNot() {
        assertThat(ProblemMapping.causedByConcurrentModification(new IllegalStateException("boom"))).isFalse();
        assertThat(ProblemMapping.causedByConcurrentModification(
                new IllegalStateException(new IllegalArgumentException("deeper")))).isFalse();
    }

    @Test
    void aCauseChainThatPointsAtItselfEnds() {
        assertThat(ProblemMapping.causedByConcurrentModification(new SelfCaused())).isFalse();
    }

    @Test
    void violationsAreSortedByField() {
        Set<ConstraintViolation<?>> violations = new LinkedHashSet<>();
        violations.add(violation("name", "must not be blank"));
        violations.add(violation("birthDate", "must be a past date"));
        violations.add(violation("email", "must be an email"));

        assertThat(ProblemMapping.violationsOf(violations)).containsExactly(
                new Problem.Violation("birthDate", "must be a past date"),
                new Problem.Violation("email", "must be an email"),
                new Problem.Violation("name", "must not be blank"));
    }

    @Test
    void aMissingTenantRoleIsARoleDenialAndEveryOtherRefusalAFineGrainedOne() {
        assertThat(ProblemMapping.denialKindOf(new TenantRoleDeniedException("Requires one of [ADMIN]")))
                .isEqualTo(DenialKind.ROLE);
        assertThat(ProblemMapping.denialKindOf(new AccessDeniedException("Not the team's coach")))
                .isEqualTo(DenialKind.FINE_GRAINED);
    }

    private static ConstraintViolation<?> violation(String field, String message) {
        ConstraintViolation<?> violation = mock(ConstraintViolation.class);
        Path path = mock(Path.class);
        when(path.toString()).thenReturn(field);
        when(violation.getPropertyPath()).thenReturn(path);
        when(violation.getMessage()).thenReturn(message);
        return violation;
    }

    /** A Throwable whose getCause() returns itself (Throwable's own never does). */
    private static final class SelfCaused extends RuntimeException {

        @Override
        public synchronized Throwable getCause() {
            return this;
        }
    }
}
