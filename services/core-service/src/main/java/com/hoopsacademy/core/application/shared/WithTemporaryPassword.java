package com.hoopsacademy.core.application.shared;

import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;

/**
 * The result of a use case that may have created a login (ADR-0024): the value plus the temporary password of that
 * new login, to be shown once to the caller. Empty when no login was created (none needed, or an existing login was
 * linked and keeps its own password).
 */
public record WithTemporaryPassword<T>(T value, Optional<TemporaryPassword> temporaryPassword) {

    public WithTemporaryPassword {
        Objects.requireNonNull(value, "value");
        Objects.requireNonNull(temporaryPassword, "temporaryPassword");
    }

    public static <T> WithTemporaryPassword<T> without(T value) {
        return new WithTemporaryPassword<>(value, Optional.empty());
    }

    public <R> WithTemporaryPassword<R> map(Function<T, R> mapper) {
        return new WithTemporaryPassword<>(mapper.apply(value), temporaryPassword);
    }
}
