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
        return Map.of("core.sample_colour", "colour codes are a fixed catalogue shared by all academies");
    }
}
