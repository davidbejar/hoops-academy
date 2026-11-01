package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.problem.ConflictException;
import jakarta.persistence.EntityManager;
import org.hibernate.exception.ConstraintViolationException;

/** Flushes so that unique/exclusion violations surface as 409 inside the repository call, not at commit. */
final class ConstraintConflicts {

    private ConstraintConflicts() {}

    static void flush(EntityManager em, String code, String message) {
        try {
            em.flush();
        } catch (ConstraintViolationException e) {
            String state = e.getSQLState();
            if ("23505".equals(state) || "23P01".equals(state)) {
                throw new ConflictException(message, code);
            }
            throw e;
        }
    }
}
