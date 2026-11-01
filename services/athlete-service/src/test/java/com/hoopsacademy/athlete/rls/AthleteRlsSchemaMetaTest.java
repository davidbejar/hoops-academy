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
        return Map.of("athlete.tenant_registry",
                "tenants known to this service with their time zone; lets the nightly job iterate tenants, holds no tenant content");
    }
}
