package com.hoopsacademy.athlete.application;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.problem.AccessDeniedException;
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
import org.junit.jupiter.api.Test;

/** Archiving is a use case without a REST operation in the contract yet: archived plans leave the list and cannot be assigned. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class PlanArchiveTest {

    static final String TENANT = "66000000-0000-4000-8000-000000000001";
    static final String TEAM = "66000000-0000-4000-8000-0000000000a1";

    @Inject ManagePlans plans;
    @Inject TenantScope tenantScope;
    @Inject CoreRosterAdapter rosterAdapter;

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void archivedPlansAreHiddenFromTheListAndCannotBeAssigned() {
        new CoreStubs().reset().roster(TENANT, TEAM, UUID.randomUUID().toString());
        rosterAdapter.clearCache();
        AuthzContext admin = member(TENANT, TenantRole.ADMIN);
        String id = api(TENANT).body(Map.of("name", "Old plan")).post("/api/athlete/training-plans").then().statusCode(201)
                .extract().path("id");
        PlanId plan = new PlanId(UUID.fromString(id));

        tenantScope.runAs(TenantId.parse(TENANT), () -> plans.setArchived(admin, plan, true));

        api(TENANT).queryParam("q", "Old plan").get("/api/athlete/training-plans").then().body("page.totalElements", equalTo(0));
        api(TENANT).get("/api/athlete/training-plans/" + id).then().statusCode(200);
        lenient(TENANT).body(Map.of("planId", id, "teamId", TEAM, "dueOn", "2027-10-10")).post("/api/athlete/plan-assignments")
                .then().statusCode(422).body("code", equalTo("PLAN_ARCHIVED"));

        tenantScope.runAs(TenantId.parse(TENANT), () -> plans.setArchived(admin, plan, false));
        api(TENANT).queryParam("q", "Old plan").get("/api/athlete/training-plans").then().body("page.totalElements", equalTo(1));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT)
    void onlyStaffMayArchive() {
        AuthzContext parent = member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(), null);

        assertThatThrownBy(() -> tenantScope.runAs(TenantId.parse(TENANT),
                () -> plans.setArchived(parent, new PlanId(UUID.randomUUID()), true))).isInstanceOf(AccessDeniedException.class);
    }
}
