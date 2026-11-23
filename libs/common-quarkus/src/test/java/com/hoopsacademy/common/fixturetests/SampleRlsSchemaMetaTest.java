package com.hoopsacademy.common.fixturetests;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsSchemaMetaTest;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.util.Map;

/** How a service uses the meta-test: subclass, declare global tables with a reason. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class SampleRlsSchemaMetaTest extends RlsSchemaMetaTest {

    @Override
    protected Map<String, String> globalTables() {
        return Map.of("core.sample_colour", "colour codes are a fixed catalogue shared by all academies",
                "core.replica_tenant", "the replica's tenant ids, so retention can enter each tenant (ADR-0037)",
                "core.parked_event", "a record that broke its contract may name no tenant (ADR-0037)");
    }

    @Override
    protected Map<String, String> nullableTenantTables() {
        return Map.of("core.sample_template", "tenant_id");
    }
}
