package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsSchemaMetaTest;
import com.hoopsacademy.game.support.CoreWireMockResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.common.ResourceArg;
import java.util.Map;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class GameRlsSchemaMetaTest extends RlsSchemaMetaTest {

    @Override
    protected Map<String, String> globalTables() {
        return Map.of("game.parked_event", "roster events that failed validation may name no tenant; the app role may "
                + "only insert and prune inspected rows (ADR-0037, WP82), operators read them as the owner",
                "game.replica_tenant", "ids of the tenants the replica holds rows of, so the retention job can enter "
                + "each one (WP82); no tenant content");
    }
}
