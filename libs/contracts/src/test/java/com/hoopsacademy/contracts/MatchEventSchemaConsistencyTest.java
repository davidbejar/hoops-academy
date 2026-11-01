package com.hoopsacademy.contracts;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.models.media.Discriminator;
import io.swagger.v3.oas.models.media.Schema;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The OpenAPI schema {@code MatchEvent} (openapi/game.yaml, OpenAPI 3.0.3) and the JSON Schema
 * events/match-event.schema.json (2020-12) are maintained side by side because OpenAPI 3.0 cannot reference a 2020-12
 * schema. This test keeps them in lock-step: same event types, same per-type schema names, same required fields and
 * same payload shapes and enum values.
 */
class MatchEventSchemaConsistencyTest {

    private static final String OPENAPI_REF_PREFIX = "#/components/schemas/";
    private static final String JSON_REF_PREFIX = "#/$defs/";

    private static Map<String, Schema<?>> openApiSchemas;
    private static JsonNode jsonSchema;

    /** Effective, flattened shape of an object schema (allOf and $ref resolved). */
    private record Shape(Set<String> required, Map<String, String> propertyRefs, Map<String, List<String>> enums) {
    }

    @BeforeAll
    static void load() throws IOException {
        openApiSchemas = new LinkedHashMap<>();
        OpenApiSpecs.parse("game").getOpenAPI().getComponents().getSchemas().forEach(openApiSchemas::put);
        jsonSchema = new ObjectMapper().readTree(ContractFiles.matchEventSchema().toFile());
    }

    @Test
    void eventTypeListsAreIdentical() {
        List<String> openApiTypes = enumValues(openApiSchemas.get("MatchEventType"));
        List<String> jsonTypes = texts(jsonSchema.at("/$defs/MatchEventType/enum"));

        assertThat(jsonTypes).containsExactlyElementsOf(openApiTypes);
        assertThat(discriminator().getMapping().keySet()).containsExactlyInAnyOrderElementsOf(openApiTypes);
        assertThat(jsonDispatch().keySet()).containsExactlyInAnyOrderElementsOf(openApiTypes);
    }

    @Test
    void discriminatorIsTheTypeProperty() {
        assertThat(discriminator().getPropertyName()).isEqualTo("type");
        int oneOfCount = openApiSchemas.get("MatchEvent").getOneOf().size();
        assertThat(oneOfCount).isEqualTo(discriminator().getMapping().size());
    }

    @Test
    void everyTypeUsesTheSameSchemaNameOnBothSides() {
        Map<String, String> openApi = new TreeMap<>();
        discriminator().getMapping().forEach((type, ref) -> openApi.put(type, ref.substring(OPENAPI_REF_PREFIX.length())));

        assertThat(new TreeMap<>(jsonDispatch())).isEqualTo(openApi);
    }

    @Test
    void everyTypeHasTheSameShapeOnBothSides() {
        jsonDispatch().forEach((type, schemaName) -> {
            Shape openApi = openApiShape(openApiSchemas.get(schemaName));
            Shape json = jsonShape(jsonSchema.at("/$defs/" + schemaName));

            assertThat(json.required()).as(type + " required").isEqualTo(openApi.required());
            assertThat(withoutTypeProperty(json.propertyRefs().keySet()))
                    .as(type + " properties").isEqualTo(withoutTypeProperty(openApi.propertyRefs().keySet()));
            assertThat(json.propertyRefs().get("payload")).as(type + " payload schema name")
                    .isEqualTo(openApi.propertyRefs().get("payload"));
        });
    }

    @Test
    void everyPayloadHasTheSameShapeOnBothSides() {
        Set<String> payloadNames = openApiSchemas.keySet().stream()
                .filter(name -> name.endsWith("Payload"))
                .collect(Collectors.toCollection(LinkedHashSet::new));

        assertThat(payloadNames).isNotEmpty().allSatisfy(name -> {
            Shape openApi = openApiShape(openApiSchemas.get(name));
            Shape json = jsonShape(jsonSchema.at("/$defs/" + name));

            assertThat(json.required()).as(name + " required").isEqualTo(openApi.required());
            assertThat(json.propertyRefs().keySet()).as(name + " properties").isEqualTo(openApi.propertyRefs().keySet());
            assertThat(json.enums()).as(name + " enums").isEqualTo(openApi.enums());
        });
    }

    // ------------------------------------------------------------------ OpenAPI side

    private static Discriminator discriminator() {
        return openApiSchemas.get("MatchEvent").getDiscriminator();
    }

    private static Shape openApiShape(Schema<?> schema) {
        Shape shape = new Shape(new LinkedHashSet<>(), new LinkedHashMap<>(), new TreeMap<>());
        collectOpenApi(schema, shape);
        return shape;
    }

    @SuppressWarnings("rawtypes") // swagger-models exposes raw Schema in allOf / properties
    private static void collectOpenApi(Schema<?> schema, Shape shape) {
        if (schema.get$ref() != null) {
            collectOpenApi(openApiSchemas.get(schema.get$ref().substring(OPENAPI_REF_PREFIX.length())), shape);
            return;
        }
        List<Schema> allOf = Objects.requireNonNullElse(schema.getAllOf(), List.of());
        allOf.forEach(part -> collectOpenApi(part, shape));
        shape.required().addAll(Objects.requireNonNullElse(schema.getRequired(), List.of()));
        Map<String, Schema> properties = Objects.requireNonNullElse(schema.getProperties(), Map.of());
        properties.forEach((name, property) -> {
            String ref = property.get$ref();
            shape.propertyRefs().put(name, ref == null ? null : ref.substring(OPENAPI_REF_PREFIX.length()));
            if (property.getEnum() != null) {
                shape.enums().put(name, enumValues(property));
            }
        });
    }

    private static List<String> enumValues(Schema<?> schema) {
        List<String> values = new ArrayList<>();
        for (Object value : schema.getEnum()) {
            values.add(String.valueOf(value));
        }
        return values;
    }

    // ------------------------------------------------------------------ JSON Schema side

    /** type constant → $defs name, read from the if/then dispatch of the root allOf. */
    private static Map<String, String> jsonDispatch() {
        Map<String, String> dispatch = new LinkedHashMap<>();
        for (JsonNode entry : jsonSchema.get("allOf")) {
            if (entry.has("if")) {
                String type = entry.at("/if/properties/type/const").asText();
                String target = entry.at("/then/$ref").asText().substring(JSON_REF_PREFIX.length());
                dispatch.put(type, target);
            }
        }
        return dispatch;
    }

    private static Shape jsonShape(JsonNode schema) {
        assertThat(schema.isMissingNode()).as("JSON Schema $defs entry exists").isFalse();
        Shape shape = new Shape(new LinkedHashSet<>(), new LinkedHashMap<>(), new TreeMap<>());
        collectJson(schema, shape);
        return shape;
    }

    private static void collectJson(JsonNode schema, Shape shape) {
        if (schema.has("$ref") && schema.size() == 1) {
            collectJson(jsonSchema.at("/$defs/" + schema.get("$ref").asText().substring(JSON_REF_PREFIX.length())), shape);
            return;
        }
        schema.path("allOf").forEach(part -> collectJson(part, shape));
        schema.path("required").forEach(name -> shape.required().add(name.asText()));
        schema.path("properties").properties().forEach(property -> {
            JsonNode value = property.getValue();
            String ref = value.has("$ref") ? value.get("$ref").asText().substring(JSON_REF_PREFIX.length()) : null;
            shape.propertyRefs().merge(property.getKey(), Objects.requireNonNullElse(ref, ""), (a, b) -> a.isEmpty() ? b : a);
            if (value.has("enum")) {
                shape.enums().put(property.getKey(), texts(value.get("enum")));
            }
        });
    }

    private static List<String> texts(JsonNode array) {
        return StreamSupport.stream(array.spliterator(), false).map(JsonNode::asText).toList();
    }

    private static Set<String> withoutTypeProperty(Set<String> names) {
        return names.stream().filter(name -> !name.equals("type")).collect(Collectors.toSet());
    }
}
