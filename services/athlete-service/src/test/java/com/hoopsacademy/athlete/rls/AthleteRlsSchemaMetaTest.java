package com.hoopsacademy.athlete.rls;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsSchemaMetaTest;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.util.Map;

/**
 * Every table of the athlete schema has forced RLS with a tenant policy, is a declared global table, or is a declared
 * shared global+tenant table (owner column {@code owner_tenant_id}, null = global row): those are checked by the
 * common inspector for forced RLS, a tenant policy and one policy per command (no FOR ALL), and their row-level
 * behaviour is proved by TemplateRlsIsolationTest and HealthRlsIsolationTest.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class AthleteRlsSchemaMetaTest extends RlsSchemaMetaTest {

    private static final String OWNER = "owner_tenant_id";

    @Override
    protected Map<String, String> globalTables() {
        return Map.of("athlete.tenant_registry",
                "tenants known to this service with their time zone; lets the nightly job iterate tenants, holds no tenant content",
                "athlete.parked_event",
                "roster records the consumer rejected before any tenant is bound: topic, offset, key and validation messages only");
    }

    @Override
    protected Map<String, String> nullableTenantTables() {
        return Map.of(
                "athlete.training_plan", OWNER,
                "athlete.plan_item", OWNER,
                "athlete.physical_test_type", OWNER,
                "athlete.physical_test_norm", OWNER);
    }
}
