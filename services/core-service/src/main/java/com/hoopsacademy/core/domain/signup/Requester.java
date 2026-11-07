package com.hoopsacademy.core.domain.signup;

import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Require;
import java.util.Objects;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * Who asked for an academy: an optional name, the e-mail that becomes the first administrator's login, the role they
 * gave and the language of the page they used (the decision e-mail is written in it).
 */
public record Requester(Optional<String> name, String email, RequesterRole role, AppLocale locale) {

    public static final int MAX_NAME = 120;
    public static final int MAX_EMAIL = 254;
    /** local@domain, no whitespace, control characters or a second {@code @} (header injection, ADR-0044). */
    private static final Pattern EMAIL = Pattern.compile("^[^@\\s\\p{Cc}\\p{Cf}]+@[^@\\s\\p{Cc}\\p{Cf}]+$");

    public Requester {
        Objects.requireNonNull(name, "name");
        name = name.map(value -> PlainText.line(value, "name", MAX_NAME));
        email = validEmail(email);
        if (role == null) {
            throw Require.violation("role", "role is required");
        }
        locale = Objects.requireNonNullElse(locale, AppLocale.EN);
    }

    /** From the form: a blank name means none, an absent locale English. */
    public static Requester of(String name, String email, RequesterRole role, AppLocale locale) {
        return new Requester(Optional.ofNullable(name).filter(value -> !value.isBlank()), email, role, locale);
    }

    private static String validEmail(String raw) {
        String value = raw == null ? "" : raw.strip();
        if (value.length() > MAX_EMAIL || !EMAIL.matcher(value).matches()) {
            throw Require.violation("email", "email must be a valid address of at most " + MAX_EMAIL + " characters");
        }
        return value;
    }
}
