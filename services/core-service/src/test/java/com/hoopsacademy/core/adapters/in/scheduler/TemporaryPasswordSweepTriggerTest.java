package com.hoopsacademy.core.adapters.in.scheduler;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.SideEffectsProfile;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.util.UUID;
import java.util.function.BooleanSupplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The two events that start a temporary-password sweep (ADR-0028): a temporary password being issued and the first
 * sign-in of an invited person. The sweep runs in the background after the request's transaction committed, under
 * the cluster lock; the request never waits for it and never fails because of it. Other test classes run with
 * {@code hoops.temporary-password.sweep-on-events=false} and call the sweep directly.
 */
@QuarkusTest
@TestProfile(SideEffectsProfile.class)
@CoreTestResources
class TemporaryPasswordSweepTriggerTest {

    /**
     * How long a positive wait may take before it fails. Generous on purpose: the waits end as soon as their condition
     * holds, so the bound only decides when a broken trigger is reported, and parallel builds slow the sweep down.
     */
    private static final Duration PATIENCE = Duration.ofSeconds(90);
    /** The Keycloak answer the sweep waits for in the "request does not wait" test. */
    private static final Duration SLOW_KEYCLOAK = Duration.ofSeconds(10);

    @InjectWireMock
    WireMockServer keycloak;

    @BeforeEach
    void noSweepLeftRunning() {
        KeycloakStubs.installDefaults(keycloak);
        await("no sweep running", TemporaryPasswordSweepTriggerTest::sweepLockFree);
    }

    @Test
    @TestSecurity(user = TenantUser.SUBJECT)
    void issuingATemporaryPasswordSweepsInTheBackground() {
        String due = dueLogin();

        invite("issued.trigger@example.com").statusCode(201);

        await("the due login expired", () -> expired(due));
    }

    @Test
    @TestSecurity(user = "sweep-first-sign-in")
    void theFirstSignInOfAnInvitedPersonSweepsInTheBackground() {
        String due = dueLogin();
        String tenant = Members.newTenant();
        UUID person = CoreDb.person(tenant, CoreDb.login("sweep-first-sign-in"), "Fi", "Rst", null, null, null,
                TenantRole.COACH);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c,
                "update core.person set invitation_status = 'PENDING' where id = ?", person));

        given().filter(Contract.CORE).get("/api/core/me").then().statusCode(200);

        await("the due login expired", () -> expired(due));
    }

    @Test
    @TestSecurity(user = TenantUser.SUBJECT)
    void aSignInThatAcceptsNoInvitationStartsNoSweep() throws Exception {
        String due = dueLogin();
        String tenant = Members.newTenant();
        CoreDb.person(tenant, CoreDb.login(TenantUser.SUBJECT), "Al", "Ready", null, null, null, TenantRole.COACH);

        given().filter(Contract.CORE).get("/api/core/me").then().statusCode(200);

        Thread.sleep(1500); // guards a negative assertion (no sweep started): a poll could not end it earlier
        assertThat(expired(due)).isFalse();
        keycloak.verify(0, KeycloakStubs.credentialsRead(due));
    }

    @Test
    @TestSecurity(user = TenantUser.SUBJECT)
    void theRequestNeitherWaitsForTheSweepNorFailsBecauseOfIt() {
        String slow = dueLogin();
        KeycloakStubs.slowCredentials(keycloak, slow, (int) SLOW_KEYCLOAK.toMillis());
        String broken = dueLogin();
        KeycloakStubs.login(keycloak, broken, "broken.sweep@example.com");
        KeycloakStubs.loginUpdateFails(keycloak, broken);

        long started = System.nanoTime();
        invite("slow.trigger@example.com").statusCode(201);
        Duration took = Duration.ofNanos(System.nanoTime() - started);

        // a request that waited for the sweep would take at least the slow Keycloak answer, whatever the load
        assertThat(took).isLessThan(SLOW_KEYCLOAK);
        await("the sweep started", () -> !keycloak.findAll(KeycloakStubs.credentialsRead(slow)).isEmpty());
        await("the sweep finished", TemporaryPasswordSweepTriggerTest::sweepLockFree);
        assertThat(expired(slow)).isTrue();
        assertThat(expired(broken)).as("Keycloak failed: retried by the next sweep").isFalse();
    }

    private io.restassured.response.ValidatableResponse invite(String email) {
        String tenant = Members.newTenant();
        Members.signIn(tenant, TenantRole.ADMIN);
        KeycloakStubs.createdUserGets(keycloak, UUID.randomUUID().toString());
        return Contract.forTenant(tenant).contentType(ContentType.JSON)
                .body("""
                        {"givenName":"Tri","familyName":"Gger","email":"%s","roles":["PARENT"]}""".formatted(email))
                .post("/api/core/members").then();
    }

    /** A pending person of a fresh academy whose temporary password was issued four days ago. */
    private static String dueLogin() {
        String sub = UUID.randomUUID().toString();
        String tenant = Members.newTenant();
        UUID person = CoreDb.person(tenant, CoreDb.appUser(sub, sub + "@example.com"), "Du", "E", null, null, null,
                TenantRole.PARENT);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c,
                "update core.person set invitation_status = 'PENDING' where id = ?", person));
        CoreDb.temporaryPasswordIssued(sub, "4 days");
        return sub;
    }

    private static boolean expired(String sub) {
        return CoreDb.temporaryPassword(sub).get("expiredAt") != null;
    }

    /** True when no sweep holds the cluster lock (probe: take and release it at once on another connection). */
    private static boolean sweepLockFree() {
        long key = TenantScope.advisoryKey(TemporaryPasswordSweepJob.LOCK);
        try (Connection probe = RlsTestDatabase.fromConfig().openAsApp();
                PreparedStatement take = probe.prepareStatement("select pg_try_advisory_lock(?)")) {
            take.setLong(1, key);
            try (ResultSet rs = take.executeQuery()) {
                rs.next();
                if (!rs.getBoolean(1)) {
                    return false;
                }
            }
            try (PreparedStatement release = probe.prepareStatement("select pg_advisory_unlock(?)")) {
                release.setLong(1, key);
                release.execute();
            }
            return true;
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private static void await(String what, BooleanSupplier condition) {
        long deadline = System.nanoTime() + PATIENCE.toNanos();
        while (!condition.getAsBoolean()) {
            if (System.nanoTime() > deadline) {
                throw new AssertionError("timed out waiting for: " + what);
            }
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new AssertionError("interrupted waiting for: " + what, e);
            }
        }
    }
}
