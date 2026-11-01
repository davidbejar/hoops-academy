package com.hoopsacademy.core.domain.identity;

import com.hoopsacademy.core.domain.shared.AppLocale;
import java.util.Objects;

/**
 * A platform login: the Keycloak subject plus the few preferences core keeps globally. Names live on the
 * tenant-scoped person rows, never here.
 *
 * @param locale preferred UI language, {@code null} until the user chooses one
 */
public record AppUser(UserId id, String subject, String email, AppLocale locale) {

    public AppUser {
        Objects.requireNonNull(id, "id");
        if (subject == null || subject.isBlank()) {
            throw new IllegalArgumentException("subject is required");
        }
    }

    public static AppUser register(String subject, String email) {
        return new AppUser(UserId.random(), subject, email, null);
    }

    public AppUser withLocale(AppLocale newLocale) {
        return new AppUser(id, subject, email, newLocale);
    }
}
