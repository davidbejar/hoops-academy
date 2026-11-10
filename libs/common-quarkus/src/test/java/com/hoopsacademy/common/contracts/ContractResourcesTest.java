package com.hoopsacademy.common.contracts;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.UncheckedIOException;
import org.junit.jupiter.api.Test;

/**
 * The decoders read their JSON Schemas from the contracts jar at startup (WP98, the WP88 follow-up): a build without
 * the jar fails the start with an {@link IllegalStateException} that names the resource.
 */
class ContractResourcesTest {

    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    void readsAResourceAsJson() {
        JsonNode schema = ContractResources.json(mapper, ContractResourcesTest.class,
                "/contracts-fixture/valid.schema.json");

        assertThat(schema.path("type").asText()).isEqualTo("object");
    }

    @Test
    void aMissingResourceFailsTheStartNamingIt() {
        assertThatThrownBy(() -> ContractResources.json(mapper, ContractResourcesTest.class, "/events/core.nothing.json"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("/events/core.nothing.json is not on the classpath (is the contracts jar a dependency?)");
    }

    @Test
    void aResourceThatIsNoJsonFailsTheStart() {
        assertThatThrownBy(() -> ContractResources.json(mapper, ContractResourcesTest.class,
                "/contracts-fixture/broken.schema.json"))
                .isInstanceOf(UncheckedIOException.class).hasMessageContaining("broken.schema.json");
    }
}
