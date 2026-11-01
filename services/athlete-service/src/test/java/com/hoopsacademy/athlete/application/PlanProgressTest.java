package com.hoopsacademy.athlete.application;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.domain.AssignmentId;
import com.hoopsacademy.athlete.domain.CompletionStatus;
import com.hoopsacademy.athlete.domain.PlanProgress;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Per-assignment progress: counts by status and per player over the CURRENT roster (no REST operation in the contract yet). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class PlanProgressTest {

    static final String TENANT = "65000000-0000-4000-8000-000000000001";
    static final String TEAM = "65000000-0000-4000-8000-0000000000a1";
    static final String P1 = "65000000-0000-4000-8000-0000000000b1";
    static final String P2 = "65000000-0000-4000-8000-0000000000b2";
    static final String P3 = "65000000-0000-4000-8000-0000000000b3";

    @Inject ManageCompletions completions;
    @Inject TenantScope tenantScope;
    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, P1, P2).knownPlayers(TENANT, P1, P2, P3);
    }

    private PlanProgress progressAs(AuthzContext caller, String assignment) {
        return tenantScope.runAs(TenantId.parse(TENANT),
                () -> completions.progress(caller, new AssignmentId(UUID.fromString(assignment))));
    }

    private String assignedWithAnswers() {
        String plan = api(TENANT).body(Map.of("name", "Progress")).post("/api/athlete/training-plans")
                .then().statusCode(201).extract().path("id");
        String assignment = api(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "dueOn", "2027-10-10"))
                .post("/api/athlete/plan-assignments").then().statusCode(201).extract().path("id");
        api(TENANT).body(Map.of("status", "DONE")).put("/api/athlete/plan-assignments/" + assignment + "/completions/" + P1)
                .then().statusCode(200);
        return assignment;
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void staffSeeCountsPerStatusAndWhoHasNotAnswered() {
        String assignment = assignedWithAnswers();

        PlanProgress progress = progressAs(member(TENANT, TenantRole.ADMIN), assignment);

        assertThat(progress.total()).isEqualTo(2);
        assertThat(progress.count(CompletionStatus.DONE)).isEqualTo(1);
        assertThat(progress.notRecorded()).isEqualTo(1);
        assertThat(progress.players()).extracting(p -> p.playerId().toString()).containsExactly(P1, P2);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void newRosterMembersAppearAtReadTime() {
        String assignment = assignedWithAnswers();
        core.roster(TENANT, TEAM, P1, P2, P3);
        rosterAdapter.clearCache();

        PlanProgress progress = progressAs(member(TENANT, TenantRole.ADMIN), assignment);

        assertThat(progress.total()).isEqualTo(3);
        assertThat(progress.notRecorded()).isEqualTo(2);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void aParentSeesOnlyTheirChildAndUnrelatedCallersGetNothing() {
        String assignment = assignedWithAnswers();
        AuthzContext parent = member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(P1), null);
        PlanProgress mine = progressAs(parent, assignment);

        assertThat(mine.total()).isEqualTo(1);
        assertThat(mine.players().get(0).playerId()).isEqualTo(new PlayerId(UUID.fromString(P1)));

        AuthzContext stranger = member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(P3), null);
        assertThatThrownBy(() -> progressAs(stranger, assignment)).isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> progressAs(parent, UUID.randomUUID().toString())).isInstanceOf(NotFoundException.class);
    }
}
