package com.hoopsacademy.common.fixturetests;

import com.hoopsacademy.common.testing.ColumnFixture;
import com.hoopsacademy.common.testing.GenericRlsIsolationTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.util.Map;

/** How a service uses the generic isolation suite: subclass, provide fixtures for FK columns. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class SampleGenericRlsIsolationTest extends GenericRlsIsolationTest {

    @Override
    protected Map<String, Map<String, ColumnFixture>> fixtureOverrides() {
        return Map.of("core.sample_widget_part", Map.of("widget_id", SampleFixtures::insertWidget));
    }
}
