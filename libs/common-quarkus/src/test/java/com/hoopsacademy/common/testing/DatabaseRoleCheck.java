package com.hoopsacademy.common.testing;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Whether Postgres row-level security binds the connection's {@code current_user}. RLS does not apply to a superuser
 * or a {@code BYPASSRLS} role, and it does not apply to a table's owner unless the table FORCEs it. A role that can
 * CREATE in a schema can add a table without any policy. So the role must be none of these, and must not be a member
 * of a role that is (membership allows {@code SET ROLE}).
 */
public final class DatabaseRoleCheck {

    private static final String USER_SCHEMAS = """
            n.nspname not in ('pg_catalog', 'information_schema') and n.nspname not like 'pg\\_%'""";

    private static final String PRIVILEGED_ROLES_SQL = """
            select r.rolname, r.rolsuper
              from pg_roles r
             where (r.rolsuper or r.rolbypassrls) and pg_has_role(current_user, r.oid, 'MEMBER')
             order by 1""";

    private static final String OWNED_TABLES_SQL = """
            select n.nspname || '.' || c.relname, pg_get_userbyid(c.relowner)
              from pg_class c
              join pg_namespace n on n.oid = c.relnamespace
             where c.relkind in ('r', 'p') and %s
               and pg_has_role(current_user, c.relowner, 'MEMBER')
             order by 1""".formatted(USER_SCHEMAS);

    private static final String CREATE_SCHEMAS_SQL = """
            select n.nspname
              from pg_namespace n
             where %s and has_schema_privilege(current_user, n.oid, 'CREATE')
             order by 1""".formatted(USER_SCHEMAS);

    private DatabaseRoleCheck() {}

    public static String currentUser(Connection connection) throws SQLException {
        try (Statement st = connection.createStatement(); ResultSet rs = st.executeQuery("select current_user")) {
            rs.next();
            return rs.getString(1);
        }
    }

    /** Every reason RLS would not bind {@code current_user}; empty when it is a plain, non-owner role. */
    public static List<String> violations(Connection connection) throws SQLException {
        String user = currentUser(connection);
        List<String> violations = new ArrayList<>();
        try (Statement st = connection.createStatement()) {
            try (ResultSet rs = st.executeQuery(PRIVILEGED_ROLES_SQL)) {
                while (rs.next()) {
                    violations.add("%s is or acts as %s, which is %s".formatted(
                            user, rs.getString(1), rs.getBoolean(2) ? "a superuser" : "BYPASSRLS"));
                }
            }
            try (ResultSet rs = st.executeQuery(OWNED_TABLES_SQL)) {
                while (rs.next()) {
                    violations.add("%s is or acts as owner %s of %s".formatted(user, rs.getString(2), rs.getString(1)));
                }
            }
            try (ResultSet rs = st.executeQuery(CREATE_SCHEMAS_SQL)) {
                while (rs.next()) {
                    violations.add("%s may CREATE in schema %s".formatted(user, rs.getString(1)));
                }
            }
        }
        return violations;
    }
}
