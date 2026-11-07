package com.hoopsacademy.common.problem;

/** A member lacks every tenant role of {@code @RequiresTenantRole}: 403, logged as a {@code role} denial. */
public class TenantRoleDeniedException extends AccessDeniedException {

    public TenantRoleDeniedException(String message) {
        super(message);
    }
}
