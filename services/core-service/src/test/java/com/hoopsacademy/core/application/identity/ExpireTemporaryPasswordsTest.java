package com.hoopsacademy.core.application.identity;

import static org.assertj.core.api.Assertions.assertThat;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.core.adapters.in.scheduler.TemporaryPasswordSweepJob;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The sweep of ADR-0027: an unused temporary password older than {@code hoops.temporary-password.ttl} (3 days) is
 * expired — the Keycloak login is disabled and every academy where the login has a PENDING person gets an audit row;
 * a login whose owner chose a password is only forgotten; Keycloak failures are retried by the next sweep.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class ExpireTemporaryPasswordsTest {

    private static final String EXPIRED = "member.temporary_password_expired";

    @InjectWireMock
    WireMockServer keycloak;

    @Inject
    ExpireTemporaryPasswords sweep;

    @Inject
    TemporaryPasswordSweepJob job;

    @BeforeEach
    void defaults() {
        KeycloakStubs.installDefaults(keycloak);
    }

    @Test
    void anUnusedTemporaryPasswordOlderThanTheTtlIsExpiredInEveryAcademyWhereThePersonIsPending() {
        String sub = UUID.randomUUID().toString();
        UUID login = CoreDb.appUser(sub, "late@example.com");
        String first = Members.newTenant();
        String second = Members.newTenant();
        String signedInThere = Members.newTenant();
        UUID pendingInFirst = person(first, login, "PENDING");
        UUID pendingInSecond = person(second, login, "PENDING");
        person(signedInThere, login, "ACCEPTED");
        KeycloakStubs.temporaryPassword(keycloak, sub);
        CoreDb.temporaryPasswordIssued(sub, "4 days");

        sweep.run();

        keycloak.verify(1, KeycloakStubs.loginEnabled(sub, false));
        assertThat(CoreDb.temporaryPassword(sub).get("expiredAt")).isNotNull();
        assertThat(CoreDb.auditRow(first, EXPIRED)).containsEntry("targetType", "person")
                .containsEntry("targetId", pendingInFirst.toString()).containsEntry("actorSub", "system")
                .containsEntry("actorPersonId", null).containsEntry("metadata", "{}");
        assertThat(CoreDb.auditRow(second, EXPIRED)).containsEntry("targetId", pendingInSecond.toString());
        assertThat(CoreDb.auditActions(signedInThere)).doesNotContain(EXPIRED);
    }

    @Test
    void aLoginWhoseOwnerChoseAPasswordIsNeverDisabledOnlyForgotten() {
        String sub = UUID.randomUUID().toString();
        String tenant = Members.newTenant();
        person(tenant, CoreDb.appUser(sub, "chosen@example.com"), "PENDING");
        KeycloakStubs.ownPassword(keycloak, sub);
        CoreDb.temporaryPasswordIssued(sub, "10 days");

        sweep.run();

        keycloak.verify(0, KeycloakStubs.loginEnabled(sub, false));
        assertThat(CoreDb.temporaryPassword(sub)).containsEntry("issuedAt", null).containsEntry("expiredAt", null);
        assertThat(CoreDb.auditActions(tenant)).doesNotContain(EXPIRED);
    }

    @Test
    void aTemporaryPasswordYoungerThanTheTtlIsNotEvenLookedAt() {
        String sub = UUID.randomUUID().toString();
        person(Members.newTenant(), CoreDb.appUser(sub, "fresh@example.com"), "PENDING");
        CoreDb.temporaryPasswordIssued(sub, "2 days 23 hours");

        sweep.run();

        keycloak.verify(0, KeycloakStubs.credentialsRead(sub));
        assertThat(CoreDb.temporaryPassword(sub).get("issuedAt")).isNotNull();
        assertThat(CoreDb.temporaryPassword(sub).get("expiredAt")).isNull();
    }

    @Test
    void anAlreadyExpiredLoginIsNotDisabledAgain() {
        String sub = UUID.randomUUID().toString();
        String tenant = Members.newTenant();
        person(tenant, CoreDb.appUser(sub, "expired@example.com"), "PENDING");
        CoreDb.temporaryPasswordExpired(sub, "9 days");

        sweep.run();

        keycloak.verify(0, KeycloakStubs.credentialsRead(sub));
        assertThat(CoreDb.auditActions(tenant)).doesNotContain(EXPIRED);
    }

    @Test
    void aKeycloakFailureSkipsThatLoginOnlyAndTheNextSweepRetriesIt() {
        String failing = UUID.randomUUID().toString();
        String working = UUID.randomUUID().toString();
        String tenant = Members.newTenant();
        person(tenant, CoreDb.appUser(failing, "kc.down@example.com"), "PENDING");
        person(tenant, CoreDb.appUser(working, "kc.up@example.com"), "PENDING");
        KeycloakStubs.login(keycloak, failing, "kc.down@example.com");
        KeycloakStubs.loginUpdateFails(keycloak, failing);
        CoreDb.temporaryPasswordIssued(failing, "5 days");
        CoreDb.temporaryPasswordIssued(working, "5 days");

        ExpireTemporaryPasswords.Summary summary = sweep.run();

        assertThat(summary.failed()).isGreaterThanOrEqualTo(1);
        assertThat(CoreDb.temporaryPassword(failing).get("expiredAt")).as("rolled back, still due").isNull();
        assertThat(CoreDb.temporaryPassword(working).get("expiredAt")).isNotNull();
        assertThat(CoreDb.auditActions(tenant)).containsOnlyOnce(EXPIRED);

        KeycloakStubs.installDefaults(keycloak);
        sweep.run();

        assertThat(CoreDb.temporaryPassword(failing).get("expiredAt")).isNotNull();
        assertThat(CoreDb.auditActions(tenant)).filteredOn(EXPIRED::equals).hasSize(2);
    }

    @Test
    void anotherReplicaHoldingTheSweepLockMakesThisRunSkipAndTheNextRunCatchesUp() throws Exception {
        String sub = UUID.randomUUID().toString();
        person(Members.newTenant(), CoreDb.appUser(sub, "locked@example.com"), "PENDING");
        CoreDb.temporaryPasswordIssued(sub, "4 days");
        long key = TenantScope.advisoryKey(TemporaryPasswordSweepJob.LOCK);

        try (Connection otherReplica = RlsTestDatabase.fromConfig().openAsApp()) {
            advisory(otherReplica, "select pg_advisory_lock(?)", key);

            assertThat(job.run()).as("skipped").isFalse();
            assertThat(CoreDb.temporaryPassword(sub).get("expiredAt")).isNull();

            // release explicitly: close() frees a session lock only once the backend has exited (can lag)
            advisory(otherReplica, "select pg_advisory_unlock(?)", key);
        }

        assertThat(job.run()).isTrue();
        assertThat(CoreDb.temporaryPassword(sub).get("expiredAt")).isNotNull();
        assertThat(TemporaryPasswordSweepJob.LOCK).isEqualTo("core.temporary_password_sweep");
    }

    private static UUID person(String tenant, UUID login, String invitationStatus) {
        UUID person = CoreDb.person(tenant, login, "Tem", "Porary", null, null, null, TenantRole.PARENT);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c,
                "update core.person set invitation_status = ? where id = ?", invitationStatus, person));
        return person;
    }

    private static void advisory(Connection connection, String sql, long key) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, key);
            statement.execute();
        }
    }
}
