package com.hoopsacademy.core.domain.identity;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * A temporary password for a new login (ADR-0024): shown once to whoever created the login, never stored, logged or
 * audited. Within the realm's length policy ({@value #MIN_LENGTH}..{@value #MAX_LENGTH}) and free of {@code @}, so it
 * can never equal the username or e-mail (username = e-mail, ADR-0023; realm policy {@code notUsername and notEmail}).
 * {@link #toString()} never reveals the value; read it with {@link #reveal()} only where it leaves the service.
 */
public final class TemporaryPassword {

    public static final int MIN_LENGTH = 12;
    public static final int MAX_LENGTH = 128;

    private final String value;

    private TemporaryPassword(String value) {
        this.value = value;
    }

    /** @throws IllegalArgumentException (without the value in the message) when the policy is not met */
    public static TemporaryPassword of(String value) {
        if (value == null || value.length() < MIN_LENGTH || value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("A temporary password needs " + MIN_LENGTH + " to " + MAX_LENGTH
                    + " characters");
        }
        if (value.indexOf('@') >= 0) {
            throw new IllegalArgumentException("A temporary password must not look like an e-mail address");
        }
        return new TemporaryPassword(value);
    }

    public String reveal() {
        return value;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof TemporaryPassword that && MessageDigest.isEqual(bytes(), that.bytes());
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }

    @Override
    public String toString() {
        return "TemporaryPassword[***]";
    }

    private byte[] bytes() {
        return value.getBytes(StandardCharsets.UTF_8);
    }
}
