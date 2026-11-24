package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** The test harness takes the database roles from the one list in {@code 01_roles_schemas.sql} (INF-03). */
class BootstrapRolesTest {

    private static final String[] NINE = {"core_migrator", "core_app", "core_platform", "game_migrator", "game_app",
        "athlete_migrator", "athlete_app", "finance_migrator", "finance_app"};

    @Test
    void readsTheRoleListOfTheBootstrapSql() {
        Path initDir = PostgresRlsResource.locateInitDir(Path.of("").toAbsolutePath());

        assertThat(BootstrapRoles.in(initDir)).containsExactly(NINE);
    }

    @Test
    void refusesASqlWithoutTheList(@TempDir Path dir) throws IOException {
        Files.writeString(dir.resolve("01_roles_schemas.sql"), "create role x;\n");

        assertThatThrownBy(() -> BootstrapRoles.in(dir)).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("roles: begin");
    }

    @Test
    void everyRoleGetsATestPassword() {
        assertThat(TestRolePasswords.asEnvironment()).containsOnlyKeys(
                java.util.Arrays.stream(NINE).map(r -> r.toUpperCase(java.util.Locale.ROOT) + "_PASSWORD").toList());
    }
}
