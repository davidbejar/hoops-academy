package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Test data written straight to Postgres as the schema owner {@code core_migrator} — still subject to the FORCEd
 * tenant policies, so every tenant-scoped statement runs with {@code app.tenant_id} bound. Use it to arrange state;
 * assert through the API or through {@link #count}.
 */
public final class CoreDb {

    private CoreDb() {}

    @FunctionalInterface
    public interface Work<T> {
        T run(Connection connection) throws SQLException;
    }

    /** Runs {@code work} in one migrator transaction with {@code app.tenant_id = tenant} (null = no tenant). */
    public static <T> T inTenant(String tenant, Work<T> work) {
        try (Connection connection = RlsTestDatabase.fromConfig().openAsMigrator()) {
            connection.setAutoCommit(false);
            if (tenant != null) {
                bindTenant(connection, TenantId.parse(tenant));
            }
            T result = work.run(connection);
            connection.commit();
            return result;
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    public static void bindTenant(Connection connection, TenantId tenant) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
            statement.setString(1, tenant.toString());
            statement.execute();
        }
    }

    /** An ACTIVE tenant with default settings (idempotent). */
    public static void tenant(String id) {
        tenant(id, "ACTIVE");
    }

    public static void tenant(String id, String status) {
        inTenant(id, c -> {
            insertTenantRow(c, UUID.fromString(id), status);
            update(c, "insert into core.tenant_settings (tenant_id) values (?) on conflict do nothing", UUID.fromString(id));
            return null;
        });
    }

    /** Inserts the registry row only (fixture helper usable inside a migrator transaction). */
    public static void insertTenantRow(Connection c, UUID id, String status) throws SQLException {
        update(c, """
                insert into core.tenant (id, slug, name, status, timezone, default_locale)
                values (?, ?, ?, ?, 'Europe/Madrid', 'es') on conflict (id) do nothing""",
                id, "t-" + id.toString().substring(0, 13), "Academy " + id.toString().substring(0, 8), status);
    }

    public static UUID appUser(String subject, String email) {
        return inTenant(null, c -> {
            UUID id = UUID.randomUUID();
            update(c, "insert into core.app_user (id, keycloak_sub, email) values (?, ?, ?)", id, subject, email);
            return id;
        });
    }

    /** The app_user id of {@code subject}, creating the login row on first use (idempotent). */
    public static UUID login(String subject) {
        return inTenant(null, c -> {
            update(c, "insert into core.app_user (id, keycloak_sub) values (gen_random_uuid(), ?) "
                    + "on conflict (keycloak_sub) do nothing", subject);
            try (PreparedStatement statement = c.prepareStatement("select id from core.app_user where keycloak_sub = ?")) {
                statement.setString(1, subject);
                try (ResultSet rs = statement.executeQuery()) {
                    rs.next();
                    return rs.getObject(1, UUID.class);
                }
            }
        });
    }

    public static UUID person(String tenant, String given, String family, String email, TenantRole... roles) {
        return person(tenant, null, given, family, email, null, null, roles);
    }

    public static UUID person(String tenant, UUID userId, String given, String family, String email,
            LocalDate birthDate, String gender, TenantRole... roles) {
        return inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            update(c, """
                    insert into core.person (id, tenant_id, user_id, given_name, family_name, email, birth_date, gender)
                    values (?, ?, ?, ?, ?, ?, ?, ?)""",
                    id, UUID.fromString(tenant), userId, given, family, email, birthDate, gender);
            for (TenantRole role : roles) {
                update(c, "insert into core.membership_role (tenant_id, person_id, role) values (?, ?, ?)",
                        UUID.fromString(tenant), id, role.name());
            }
            if (userId != null) {
                update(c, """
                        insert into core.user_membership_index (tenant_id, keycloak_sub, person_id)
                        select ?, u.keycloak_sub, ? from core.app_user u where u.id = ?""",
                        UUID.fromString(tenant), id, userId);
            }
            return id;
        });
    }

    public static UUID player(String tenant, UUID personId) {
        return inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            update(c, "insert into core.player (id, tenant_id, person_id, status) values (?, ?, ?, 'ACTIVE')",
                    id, UUID.fromString(tenant), personId);
            return id;
        });
    }

    public static UUID guardianLink(String tenant, UUID guardianPersonId, UUID playerId) {
        return inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            update(c, "insert into core.guardian_link (id, tenant_id, guardian_person_id, player_id) values (?, ?, ?, ?)",
                    id, UUID.fromString(tenant), guardianPersonId, playerId);
            return id;
        });
    }

    /** {@code select count(*) …} as the migrator with the tenant bound (null: no tenant, global tables only). */
    public static long count(String tenant, String sql, Object... params) {
        return inTenant(tenant, c -> {
            try (PreparedStatement statement = c.prepareStatement(sql)) {
                bind(statement, params);
                try (ResultSet rs = statement.executeQuery()) {
                    rs.next();
                    return rs.getLong(1);
                }
            }
        });
    }

    /** Count over the tenant registry / billing tables as {@code core_platform}. */
    public static long countAsPlatform(String sql, Object... params) {
        try (Connection c = TestDatabases.openAsPlatform();
                PreparedStatement statement = c.prepareStatement(sql)) {
            bind(statement, params);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    public static int update(Connection c, String sql, Object... params) throws SQLException {
        try (PreparedStatement statement = c.prepareStatement(sql)) {
            bind(statement, params);
            return statement.executeUpdate();
        }
    }

    static void bind(PreparedStatement statement, Object... params) throws SQLException {
        for (int i = 0; i < params.length; i++) {
            statement.setObject(i + 1, params[i]);
        }
    }
}
