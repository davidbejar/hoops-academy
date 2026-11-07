package com.hoopsacademy.common.problem;

import com.hoopsacademy.common.security.DenialKind;
import jakarta.persistence.OptimisticLockException;
import jakarta.validation.ConstraintViolation;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import org.hibernate.StaleStateException;

/** The decisions of {@link ProblemExceptionMappers} that need no request: kept apart so PIT mutates them (WP88). */
final class ProblemMapping {

    private ProblemMapping() {
    }

    /** A lost {@code @Version} race often arrives wrapped (flush at commit, RollbackException, ...). */
    static boolean causedByConcurrentModification(Throwable e) {
        for (Throwable cause = e; cause != null; cause = cause.getCause() == cause ? null : cause.getCause()) {
            if (cause instanceof OptimisticLockException || cause instanceof StaleStateException) {
                return true;
            }
        }
        return false;
    }

    /** The violations of a rejected request, ordered by field. */
    static List<Problem.Violation> violationsOf(Collection<? extends ConstraintViolation<?>> violations) {
        return violations.stream()
                .map(violation -> new Problem.Violation(violation.getPropertyPath().toString(), violation.getMessage()))
                .sorted(Comparator.comparing(Problem.Violation::field))
                .toList();
    }

    /** The security event of a refusal: a missing tenant role, or a fine-grained rule of a use case. */
    static DenialKind denialKindOf(AccessDeniedException e) {
        return e instanceof TenantRoleDeniedException ? DenialKind.ROLE : DenialKind.FINE_GRAINED;
    }
}
