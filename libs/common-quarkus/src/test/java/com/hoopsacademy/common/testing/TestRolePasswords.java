package com.hoopsacademy.common.testing;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Fixed, test-only passwords for the bootstrap roles (consumed by {@code 02_passwords.sh}). */
public final class TestRolePasswords {

    static final List<String> ROLES = List.of(
            "core_migrator", "core_app", "core_platform",
            "game_migrator", "game_app",
            "athlete_migrator", "athlete_app");

    private TestRolePasswords() {}

    public static String of(String role) {
        if (!ROLES.contains(role)) {
            throw new IllegalArgumentException("unknown bootstrap role: " + role);
        }
        return role + "-test-password";
    }

    /** {@code CORE_APP_PASSWORD=core_app-test-password}, … for every bootstrap role. */
    static Map<String, String> asEnvironment() {
        return ROLES.stream().collect(Collectors.toMap(
                role -> role.toUpperCase(Locale.ROOT) + "_PASSWORD", Function.identity()))
                .entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> of(e.getValue())));
    }
}
