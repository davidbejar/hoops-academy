package com.hoopsacademy.athlete.adapters.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The use cases' RosterPort keeps a team's roster for the request (a test method runs in a request context) and reads
 * the source on every call outside one (a job thread). The client cache is cleared in between, so every source read
 * reaches the WireMock core.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class RequestMemoWiringTest {

    static final TenantId TENANT = TenantId.parse("c1000000-0000-4000-8000-000000000001");

    @Inject RosterPort roster;
    @Inject CoreRosterClient coreClient;

    CoreStubs core;
    String team;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        coreClient.clearCache();
        team = UUID.randomUUID().toString();
        core.roster(TENANT.toString(), team, UUID.randomUUID().toString());
    }

    @Test
    void withinARequestATeamIsReadOnce() {
        readTwice();

        assertThat(core.rosterCalls(team)).isEqualTo(1);
    }

    @Test
    void outsideARequestEveryCallReads() throws Exception {
        try (var noRequest = Executors.newSingleThreadExecutor()) {
            CompletableFuture.runAsync(this::readTwice, noRequest).get();
        }

        assertThat(core.rosterCalls(team)).isEqualTo(2);
    }

    private void readTwice() {
        TeamId id = new TeamId(UUID.fromString(team));
        roster.teamRoster(TENANT, id);
        coreClient.clearCache();
        roster.teamRoster(TENANT, id);
    }
}
