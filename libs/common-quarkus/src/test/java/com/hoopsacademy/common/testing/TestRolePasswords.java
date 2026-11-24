package com.hoopsacademy.common.testing;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Fixed, test-only passwords for the bootstrap roles (consumed by {@code 02_passwords.sh}); the roles are the list of
 * {@code 01_roles_schemas.sql} ({@link BootstrapRoles}).
 */
public final class TestRolePasswords {

    private static final class Roles {
        static final List<String> LIST = BootstrapRoles.in(PostgresRlsResource.initDirOf(Map.of()));
    }

    private TestRolePasswords() {}

    public static String of(String role) {
        if (!Roles.LIST.contains(role)) {
            throw new IllegalArgumentException("unknown bootstrap role: " + role);
        }
        return role + "-test-password";
    }

    /** {@code CORE_APP_PASSWORD=core_app-test-password}, … for every bootstrap role. */
    static Map<String, String> asEnvironment() {
        return Roles.LIST.stream().collect(Collectors.toMap(
                role -> role.toUpperCase(Locale.ROOT) + "_PASSWORD", Function.identity()))
                .entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> of(e.getValue())));
    }
}
