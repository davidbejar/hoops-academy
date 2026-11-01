package com.hoopsacademy.athlete.rls;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsSchemaMetaTest;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.util.Map;

/** Every table of the athlete schema has forced RLS with a tenant policy, or is a declared global table. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class AthleteRlsSchemaMetaTest extends RlsSchemaMetaTest {

    @Override
    protected Map<String, String> globalTables() {
        return Map.of(
                "athlete.tenant_registry",
                "tenants known to this service with their time zone; lets the nightly job iterate tenants, holds no tenant content",
                "athlete.training_plan",
                "global templates live next to tenant plans, so the owner column is nullable and named owner_tenant_id; "
                        + "RLS is forced with policy (owner_tenant_id is null or = app.current_tenant()), written only for the own tenant; "
                        + "proved by TemplateRlsIsolationTest",
                "athlete.plan_item",
                "items mirror their plan's nullable owner_tenant_id (templates); same custom policy, see TemplateRlsIsolationTest");
    }
}
