package com.hoopsacademy.core.rls;

import static com.hoopsacademy.core.testsupport.Sql.count;
import static com.hoopsacademy.core.testsupport.Sql.sqlState;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import com.hoopsacademy.core.testsupport.TestDatabases;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * {@code core.audit_event} is append-only for the application (ASVS 16.4.2): core_app may insert and read its own
 * tenant's rows but never change or delete one; core_platform (tenant lifecycle, the super admin's trail) appends and,
 * since WP34, reads every academy's rows, never changes them. The generic RLS suites cover the tenant isolation itself.
 */
@Tag("rls")
@QuarkusTest
@CoreTestResources
class AuditEventRlsTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";
    private final String tenant = UUID.randomUUID().toString();

    @BeforeEach
    void aTenant() {
        CoreDb.tenant(tenant);
    }

    @Test
    void theAppRoleAppendsAndReadsButNeverRewritesHistory() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            RlsTestDatabase.bindTenant(app, TenantId.parse(tenant));
            assertThat(sqlState(app, insert(tenant))).isEqualTo("no error");
            CoreDb.update(app, insert(tenant));
            assertThat(count(app, "select count(*) from core.audit_event")).isEqualTo(1);
            assertThat(sqlState(app, "update core.audit_event set action = 'forged'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "delete from core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "truncate core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            app.rollback();
        }
    }

    @Test
    void thePlatformRoleAppendsAndReadsEveryAcademyButNeverRewritesHistory() throws SQLException {
        String other = UUID.randomUUID().toString();
        CoreDb.tenant(other);
        try (Connection platform = TestDatabases.openAsPlatform()) {
            platform.setAutoCommit(false);
            assertThat(sqlState(platform, insert(tenant))).isEqualTo("no error");
            CoreDb.update(platform, insert(tenant));
            CoreDb.update(platform, insert(other));
            assertThat(count(platform, "select count(*) from core.audit_event where tenant_id in ('" + tenant + "', '"
                    + other + "')")).as("WP34: the super admin's trail spans academies, no tenant bound").isEqualTo(2);
            assertThat(sqlState(platform, "update core.audit_event set action = 'x'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "delete from core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "truncate core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            platform.rollback();
        }
    }

    @Test
    void thePlatformRoleStillReadsNoTenantContent() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform()) {
            // since WP91 it reads the name of persons with a login (PlatformUserReadRlsTest), never the whole row
            assertThat(sqlState(platform, "select * from core.person")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "select count(*) from core.player")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    @Test
    void theAppRoleReadsOnlyItsOwnAcademysTrail() throws SQLException {
        String other = UUID.randomUUID().toString();
        CoreDb.tenant(other);
        CoreDb.inTenant(other, c -> CoreDb.update(c, insert(other)));
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, insert(tenant)));
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            RlsTestDatabase.bindTenant(app, TenantId.parse(tenant));
            assertThat(count(app, "select count(*) from core.audit_event where tenant_id <> '" + tenant + "'")).isZero();
            assertThat(count(app, "select count(*) from core.audit_event")).isEqualTo(1);
            app.rollback();
        }
    }

    private static String insert(String tenant) {
        return "insert into core.audit_event (id, tenant_id, actor_sub, action, target_type, target_id) values ('"
                + UUID.randomUUID() + "', '" + tenant + "', 'someone', 'member.invited', 'person', 'p-1')";
    }
}
