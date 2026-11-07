package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.databind.JsonMappingException;
import com.hoopsacademy.common.security.DenialKind;
import jakarta.persistence.OptimisticLockException;
import jakarta.validation.ConstraintViolation;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.function.Predicate;
import org.hibernate.StaleStateException;

/** The decisions of {@link ProblemExceptionMappers} that need no request: kept apart so PIT mutates them (WP88). */
final class ProblemMapping {

    /** SQLSTATE character_not_in_repertoire and untranslatable_character. */
    private static final Set<String> UNSTORABLE_TEXT = Set.of("22021", "22P05");

    private ProblemMapping() {
    }

    /** A lost {@code @Version} race often arrives wrapped (flush at commit, RollbackException, ...). */
    static boolean causedByConcurrentModification(Throwable e) {
        return anyCause(e, cause -> cause instanceof OptimisticLockException || cause instanceof StaleStateException);
    }

    /** Text PostgreSQL refused ({@link UnsafeText}): NUL in {@code text} (22021) or {@code jsonb} (22P05). */
    static boolean causedByUnstorableText(Throwable e) {
        return anyCause(e, cause -> cause instanceof SQLException sql && sql.getSQLState() != null
                && UNSTORABLE_TEXT.contains(sql.getSQLState()));
    }

    /** The field a refused JSON value sat in: {@code name}, {@code tags[1]}, {@code address.city}; else {@code body}. */
    static String fieldOf(JsonMappingException e) {
        return e.getPath().stream()
                .map(ref -> ref.getFieldName() != null ? ref.getFieldName() : "[" + ref.getIndex() + "]")
                .reduce((parent, child) -> child.startsWith("[") ? parent + child : parent + "." + child)
                .orElse("body");
    }

    private static boolean anyCause(Throwable e, Predicate<Throwable> test) {
        for (Throwable cause = e; cause != null; cause = cause.getCause() == cause ? null : cause.getCause()) {
            if (test.test(cause)) {
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
