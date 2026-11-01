package com.hoopsacademy.core.rls;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsSchemaMetaTest;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.util.List;
import java.util.Map;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class CoreRlsSchemaMetaTest extends RlsSchemaMetaTest {

    @Override
    protected List<String> schemas() {
        return List.of("core", "billing");
    }

    @Override
    protected Map<String, String> globalTables() {
        return Map.of(
                "core.tenant", "the tenant registry itself (keyed by id); own RLS: core_app sees only "
                        + "id = app.current_tenant(), core_platform sees all — see TenantRegistryRlsTest",
                "core.app_user", "platform-wide login identity (id, keycloak_sub, email, locale only); never listed, "
                        + "looked up by sub or via a tenant's person row",
                "billing.plan", "global catalogue of billing plans (no tenant data)");
    }
}
