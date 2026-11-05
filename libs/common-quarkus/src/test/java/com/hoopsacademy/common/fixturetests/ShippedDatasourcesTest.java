package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.ShippedDatasources;
import java.net.URL;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Reads the users a deployment gets: prod profile, env defaults, no %test overrides. */
class ShippedDatasourcesTest {

    private static final URL SAMPLE = ShippedDatasourcesTest.class.getResource("/shipped-config/application.properties");

    @Test
    void defaultAndNamedDatasourceUsersUnderTheProdProfile() {
        ShippedDatasources shipped = ShippedDatasources.from(SAMPLE);

        assertThat(shipped.users()).isEqualTo(Map.of(
                ShippedDatasources.DEFAULT, "sample_app",
                "platform", "sample_platform",
                "reporting", "sample_reporting"));
        assertThat(shipped.flywayUser()).isEqualTo("sample_migrator");
    }
}
