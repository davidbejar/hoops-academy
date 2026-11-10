package com.hoopsacademy.core.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.TestDatabases;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * WP91 / V18 (decision 71, ADR-0029 amendment): for {@code GET /platform/users} core_platform reads every login's id,
 * e-mail and creation time and, of persons WITH a login, only the name, roles and active flag, through its own select
 * policies and column grants. Persons without a login, every other personal column and every other content table stay
 * invisible; it writes none of them. Its transaction binds the nil tenant, so the standard tenant policy matches nothing;
 * without that binding a read fails closed (42501).
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class PlatformUserReadRlsTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";
    private static final String NIL = "00000000-0000-0000-0000-000000000000";

    private final String academyA = UUID.randomUUID().toString();
    private final String academyB = UUID.randomUUID().toString();
    private UUID login;
    private UUID withLogin;
    private UUID withoutLogin;

    @BeforeEach
    void aLoginInOneAcademyAndAPersonWithoutLoginInAnother() {
        CoreDb.tenant(academyA);
        CoreDb.tenant(academyB);
        login = CoreDb.appUser("wp91-rls-" + UUID.randomUUID(), "rls-" + UUID.randomUUID() + "@example.com");
        withLogin = CoreDb.person(academyA, login, "Ada", "Admin", "ada@example.com", java.time.LocalDate.of(1990, 1, 1),
                "FEMALE", TenantRole.ADMIN, TenantRole.COACH);
        withoutLogin = CoreDb.person(academyB, "Kid", "NoLogin", null, TenantRole.PLAYER);
    }

    @Test
    void thePlatformRoleReadsTheLoginsIdEmailAndCreationOnly() throws SQLException {
        try (Connection platform = boundToNoTenant()) {
            assertThat(count(platform, "select count(*) from core.app_user where id = '" + login + "' and email like "
                    + "'rls-%' and created_at is not null")).isEqualTo(1);
            for (String column : List.of("keycloak_sub", "locale", "temporary_password_issued_at")) {
                assertThat(sqlState(platform, "select " + column + " from core.app_user"))
                        .as("core.app_user.%s", column).isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
            assertThat(sqlState(platform, "update core.app_user set email = 'x@example.com'"))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "delete from core.app_user")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            platform.rollback();
        }
    }

    @Test
    void thePlatformRoleSeesOnlyPersonsWithALoginAndOnlyTheirNameRolesAndActiveFlag() throws SQLException {
        String both = "('" + withLogin + "', '" + withoutLogin + "')";
        try (Connection platform = boundToNoTenant()) {
            assertThat(ids(platform, "select id from core.person where id in " + both)).containsExactly(withLogin);
            assertThat(count(platform, "select count(*) from core.person where id = '" + withLogin
                    + "' and given_name = 'Ada' and family_name = 'Admin' and active and tenant_id = '" + academyA
                    + "' and user_id = '" + login + "'")).isEqualTo(1);
            assertThat(count(platform, "select count(*) from core.membership_role where person_id in " + both))
                    .as("the roles of the person with a login only").isEqualTo(2);
            platform.rollback();
        }
    }

    @Test
    void personalDataAndOtherContentStayInvisibleAndNothingIsWritable() throws SQLException {
        try (Connection platform = boundToNoTenant()) {
            for (String column : List.of("email", "phone", "birth_date", "gender", "locale", "invitation_status")) {
                assertThat(sqlState(platform, "select " + column + " from core.person"))
                        .as("core.person.%s", column).isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
            for (String table : List.of("core.player", "core.guardian_link", "core.user_membership_index",
                    "core.team", "core.tenant_settings")) {
                assertThat(sqlState(platform, "select count(*) from " + table)).as(table)
                        .isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
            assertThat(sqlState(platform, "update core.person set given_name = 'X'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "delete from core.person")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "delete from core.membership_role")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "insert into core.membership_role (tenant_id, person_id, role) values ('"
                    + academyA + "', '" + withLogin + "', 'PARENT')")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            platform.rollback();
        }
    }

    @Test
    void withoutTheNilTenantBindingAPersonReadFailsClosed() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform()) {
            assertThat(sqlState(platform, "select id from core.person where id = '" + withoutLogin + "'"))
                    .as("the standard policy raises when no tenant is bound").isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    private static Connection boundToNoTenant() throws SQLException {
        Connection platform = TestDatabases.openAsPlatform();
        platform.setAutoCommit(false);
        try (PreparedStatement statement = platform.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
            statement.setString(1, NIL);
            statement.execute();
        }
        return platform;
    }

    private static long count(Connection connection, String sql) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            rs.next();
            return rs.getLong(1);
        }
    }

    private static List<UUID> ids(Connection connection, String sql) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            List<UUID> ids = new java.util.ArrayList<>();
            while (rs.next()) {
                ids.add(rs.getObject(1, UUID.class));
            }
            return ids;
        }
    }

    private static String sqlState(Connection connection, String sql) throws SQLException {
        var savepoint = connection.getAutoCommit() ? null : connection.setSavepoint();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.execute();
            return "no error";
        } catch (SQLException e) {
            return e.getSQLState();
        } finally {
            if (savepoint != null) {
                connection.rollback(savepoint);
            }
        }
    }
}
