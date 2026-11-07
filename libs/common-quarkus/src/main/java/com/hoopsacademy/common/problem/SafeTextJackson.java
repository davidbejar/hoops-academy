package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.module.SimpleModule;
import io.quarkus.jackson.ObjectMapperCustomizer;
import jakarta.inject.Singleton;

/**
 * Registers {@link SafeStringDeserializer} and {@link SafeTreeDeserializer} on the service's {@code ObjectMapper}
 * (request bodies, REST clients, events). Text Jackson reads otherwise (map keys, {@code ObjectNode} targets) is caught
 * where PostgreSQL refuses it ({@code ProblemMapping.causedByUnstorableText}).
 */
@Singleton
public class SafeTextJackson implements ObjectMapperCustomizer {

    @Override
    public void customize(ObjectMapper mapper) {
        mapper.registerModule(new SimpleModule("hoops-safe-text")
                .addDeserializer(String.class, new SafeStringDeserializer())
                .addDeserializer(JsonNode.class, new SafeTreeDeserializer()));
    }
}
