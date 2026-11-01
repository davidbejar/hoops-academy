package com.hoopsacademy.core.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * {@code core.user_membership_index} is a tenant table (generic suite) with ONE extra read path for GET /me: with the
 * nil tenant bound and {@code app.subject} set, a caller reads only the index rows of their own subject.
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class MembershipIndexRlsTest {

    private static final String NIL_TENANT = "00000000-0000-0000-0000-000000000000";

    @Test
    void subjectSeesOnlyItsOwnMembershipsAcrossTenants() throws SQLException {
        String tenantA = UUID.randomUUID().toString();
        String tenantB = UUID.randomUUID().toString();
        String alice = "alice-" + UUID.randomUUID();
        String bob = "bob-" + UUID.randomUUID();
        UUID aliceId = CoreDb.appUser(alice, null);
        UUID bobId = CoreDb.appUser(bob, null);
        CoreDb.person(tenantA, aliceId, "Alice", "A", null, null, null, TenantRole.ADMIN);
        CoreDb.person(tenantB, aliceId, "Alice", "A", null, null, null, TenantRole.PARENT);
        CoreDb.person(tenantB, bobId, "Bob", "B", null, null, null, TenantRole.COACH);

        assertThat(indexRowsVisibleTo(alice)).isEqualTo(2);
        assertThat(indexRowsVisibleTo(bob)).isEqualTo(1);
        assertThat(indexRowsVisibleTo("nobody")).isZero();
    }

    @Test
    void withoutSubjectTheNilTenantSeesNothing() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            set(app, "app.tenant_id", NIL_TENANT);
            assertThat(count(app)).isZero();
            app.rollback();
        }
    }

    private static long indexRowsVisibleTo(String subject) throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            set(app, "app.tenant_id", NIL_TENANT);
            set(app, "app.subject", subject);
            long visible = count(app);
            app.rollback();
            return visible;
        }
    }

    private static void set(Connection connection, String key, String value) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("select set_config(?, ?, true)")) {
            statement.setString(1, key);
            statement.setString(2, value);
            statement.execute();
        }
    }

    private static long count(Connection app) throws SQLException {
        try (PreparedStatement statement = app.prepareStatement("select count(*) from core.user_membership_index");
                ResultSet rs = statement.executeQuery()) {
            rs.next();
            return rs.getLong(1);
        }
    }
}
