package com.hoopsacademy.core.rls;

import com.hoopsacademy.common.testing.RlsSchemaMetaTest;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import io.quarkus.test.junit.QuarkusTest;
import java.util.List;
import java.util.Map;

@QuarkusTest
@CoreTestResources
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
                "billing.plan", "global catalogue of billing plans (no tenant data)",
                "core.academy_request", "requests for a NEW academy from anonymous visitors (WP90, ADR-0044); RLS "
                        + "forced, only core_platform has a policy — see AcademyRequestRlsTest");
    }
}
