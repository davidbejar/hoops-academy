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

    /** Pretends the login's temporary password was issued {@code age} ago (a Postgres interval, e.g. "4 days"). */
    public static void temporaryPasswordIssued(String subject, String age) {
        inTenant(null, c -> update(c, "update core.app_user set temporary_password_issued_at = now() - cast(? as interval), "
                + "temporary_password_expired_at = null where keycloak_sub = ?", age, subject));
    }

    /** Marks the login's temporary password as expired by an earlier sweep, issued {@code age} ago. */
    public static void temporaryPasswordExpired(String subject, String age) {
        inTenant(null, c -> update(c, "update core.app_user set temporary_password_issued_at = now() - cast(? as interval), "
                + "temporary_password_expired_at = now() - interval '1 hour' where keycloak_sub = ?", age, subject));
    }

    /** The login's temporary password timestamps: {@code issuedAt} and {@code expiredAt} (null when unset). */
    public static java.util.Map<String, java.time.Instant> temporaryPassword(String subject) {
        return inTenant(null, c -> {
            try (PreparedStatement statement = c.prepareStatement("select temporary_password_issued_at, "
                    + "temporary_password_expired_at from core.app_user where keycloak_sub = ?")) {
                statement.setString(1, subject);
                try (ResultSet rs = statement.executeQuery()) {
                    if (!rs.next()) {
                        throw new AssertionError("no login " + subject);
                    }
                    java.util.Map<String, java.time.Instant> row = new java.util.HashMap<>();
                    row.put("issuedAt", instant(rs, 1));
                    row.put("expiredAt", instant(rs, 2));
                    return row;
                }
            }
        });
    }

    private static java.time.Instant instant(ResultSet rs, int column) throws SQLException {
        java.time.OffsetDateTime value = rs.getObject(column, java.time.OffsetDateTime.class);
        return value == null ? null : value.toInstant();
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

    /** The audit actions of {@code tenant} in insertion order (core.audit_event, ADR-0017). */
    public static java.util.List<String> auditActions(String tenant) {
        return inTenant(tenant, c -> {
            java.util.List<String> actions = new java.util.ArrayList<>();
            try (PreparedStatement statement = c.prepareStatement(
                    "select action from core.audit_event order by seq");
                    ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    actions.add(rs.getString(1));
                }
            }
            return actions;
        });
    }

    /**
     * Arranges one audit row of {@code tenant} at {@code at} (the writers stamp {@code now()}; the read API is tested
     * against fixed times). Returns the row id.
     */
    public static UUID auditEvent(String tenant, java.time.Instant at, String actorSub, UUID actorPersonId,
            String action, String targetType, Object targetId, String metadataJson) {
        return inTenant(tenant, c -> {
            UUID id = UUID.randomUUID();
            update(c, """
                    insert into core.audit_event (id, tenant_id, actor_sub, actor_person_id, action, target_type,
                                                  target_id, metadata, at)
                    values (?, ?, ?, ?, ?, ?, ?, cast(? as jsonb), ?)""",
                    id, UUID.fromString(tenant), actorSub, actorPersonId, action, targetType, String.valueOf(targetId),
                    metadataJson, java.sql.Timestamp.from(at));
            return id;
        });
    }

    /** The newest audit row of {@code action}: actorSub, actorPersonId, targetType, targetId, metadata (json text). */
    public static java.util.Map<String, String> auditRow(String tenant, String action) {
        return inTenant(tenant, c -> {
            try (PreparedStatement statement = c.prepareStatement("select actor_sub, actor_person_id::text, "
                    + "target_type, target_id, metadata::text from core.audit_event where action = ? "
                    + "order by seq desc limit 1")) {
                statement.setString(1, action);
                try (ResultSet rs = statement.executeQuery()) {
                    if (!rs.next()) {
                        throw new AssertionError("no audit event " + action + " in tenant " + tenant);
                    }
                    java.util.Map<String, String> row = new java.util.HashMap<>();
                    row.put("actorSub", rs.getString(1));
                    row.put("actorPersonId", rs.getString(2));
                    row.put("targetType", rs.getString(3));
                    row.put("targetId", rs.getString(4));
                    row.put("metadata", rs.getString(5));
                    return row;
                }
            }
        });
    }

    /**
     * The tables of schema {@code core} with a row (visible with {@code tenant} bound) whose text form contains
     * {@code text} — used to prove that a secret is never written to the database (audit, outbox, persons, …).
     */
    public static java.util.List<String> tablesContaining(String tenant, String text) {
        return inTenant(tenant, c -> {
            java.util.List<String> tables = new java.util.ArrayList<>();
            try (PreparedStatement list = c.prepareStatement(
                    "select table_name from information_schema.tables where table_schema = 'core' "
                            + "and table_type = 'BASE TABLE' order by table_name");
                    ResultSet rs = list.executeQuery()) {
                while (rs.next()) {
                    tables.add(rs.getString(1));
                }
            }
            java.util.List<String> hits = new java.util.ArrayList<>();
            for (String table : tables) {
                try (PreparedStatement scan = c.prepareStatement(
                        "select count(*) from core.\"" + table + "\" t where t::text like ?")) {
                    scan.setString(1, "%" + text + "%");
                    try (ResultSet rs = scan.executeQuery()) {
                        rs.next();
                        if (rs.getLong(1) > 0) {
                            hits.add(table);
                        }
                    }
                }
            }
            if (tables.size() < 10) {
                throw new AssertionError("expected the core tables to be visible, saw " + tables);
            }
            return hits;
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

    public static void bind(PreparedStatement statement, Object... params) throws SQLException {
        for (int i = 0; i < params.length; i++) {
            statement.setObject(i + 1, params[i]);
        }
    }
}
