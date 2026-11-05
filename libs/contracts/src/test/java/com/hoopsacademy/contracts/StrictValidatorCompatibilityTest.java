package com.hoopsacademy.contracts;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.model.Request;
import com.atlassian.oai.validator.model.SimpleResponse;
import com.atlassian.oai.validator.report.ValidationReport;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import io.swagger.v3.oas.models.media.Schema;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.FieldSource;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The contracts must be checkable by swagger-request-validator in its default, strict configuration (no
 * {@code withResolveCombinators}, no message muted), which is how every service test and the e2e journey validate.
 * That validator injects {@code additionalProperties: false} into every object schema with {@code properties}, so an
 * object composed with {@code allOf} from several property-bearing parts rejects each part's properties in the other
 * parts. Hence: response and request objects are plain objects; {@code allOf} only wraps a single {@code $ref} (to add
 * {@code nullable}, a description or a narrowing {@code enum}). A schema that repeats the fields of another schema
 * or of a mixin (a field group under {@code components.x-mixins}, not a wire type) names it in {@code x-extends}, and
 * this test keeps the copies identical.
 */
class StrictValidatorCompatibilityTest {

    private static final List<String> SPECS = List.of("common", "core", "game", "athlete");
    private static final List<String> SERVICES = OpenApiSpecs.SERVICES;
    private static final String SCHEMA_REF_PREFIX = "#/components/schemas/";
    private static final String EXTENDS = "x-extends";
    private static final String MIXINS = "x-mixins";
    private static final String FEED_PATH = "/api/game/matches/0190b6a0-0000-7000-8000-0000000000ff/events";
    private static final ObjectMapper JSON = new ObjectMapper();
    private static final ObjectMapper YAML = new ObjectMapper(new YAMLFactory());

    private static OpenApiInteractionValidator strictGameValidator;

    /** One schema node reached from a component schema, with a readable location for failure messages. */
    private record Located(String location, Schema<?> schema) {
    }

    @BeforeAll
    static void strictValidator() {
        strictGameValidator = OpenApiInteractionValidator
                .createForSpecificationUrl(ContractFiles.openApi("game").toUri().toString())
                .build();
    }

    @ParameterizedTest
    @FieldSource("SPECS")
    void everyAllOfWrapsASingleSchema(String spec) {
        List<Located> composed = allSchemaNodes(spec).stream()
                .filter(node -> node.schema().getAllOf() != null && node.schema().getAllOf().size() > 1)
                .toList();

        assertThat(composed).as(spec + ": allOf with several parts (flatten into a plain object, see x-extends)")
                .extracting(Located::location).isEmpty();
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void extendedSchemasRepeatEveryPropertyOfTheirBases(String service) throws IOException {
        JsonNode components = yaml(service).path("components");
        Map<String, JsonNode> extending = new LinkedHashMap<>();
        components.path("schemas").properties().forEach(entry -> {
            if (entry.getValue().has(EXTENDS)) {
                extending.put(entry.getKey(), entry.getValue());
            }
        });

        assertThat(extending).as(service + " schemas with " + EXTENDS).isNotEmpty();
        extending.forEach((name, schema) -> schema.get(EXTENDS).forEach(baseName -> {
            JsonNode base = base(components, baseName.asText());
            assertThat(base.isMissingNode()).as(name + " extends unknown schema or mixin " + baseName).isFalse();
            assertThat(texts(schema.path("required"))).as(name + " repeats the required fields of " + baseName)
                    .containsAll(texts(base.path("required")));
            base.path("properties").properties().forEach(property -> {
                JsonNode copy = schema.path("properties").path(property.getKey());
                String where = name + "." + property.getKey() + " (from " + baseName.asText() + ")";
                assertThat(copy.isMissingNode()).as(where + " present").isFalse();
                if (!narrows(copy, property.getValue())) {
                    assertThat(copy).as(where + " identical").isEqualTo(property.getValue());
                }
            });
        }));
    }

    @ParameterizedTest
    @FieldSource("SERVICES")
    void everyMixinIsExtended(String service) throws IOException {
        JsonNode components = yaml(service).path("components");
        Set<String> extended = new HashSet<>();
        components.path("schemas").forEach(schema -> extended.addAll(texts(schema.path(EXTENDS))));

        List<String> mixins = new ArrayList<>();
        components.path(MIXINS).fieldNames().forEachRemaining(mixins::add);

        assertThat(mixins).as(service + " " + MIXINS).isSubsetOf(extended);
    }

    @Test
    void everyMatchEventVariantExtendsTheBaseEvent() throws IOException {
        JsonNode schemas = yaml("game").at("/components/schemas");
        List<String> variants = schemas.at("/MatchEvent/oneOf").findValues("$ref").stream()
                .map(ref -> ref.asText().substring(SCHEMA_REF_PREFIX.length())).toList();

        assertThat(variants).hasSize(schemas.at("/MatchEventType/enum").size()).allSatisfy(variant ->
                assertThat(texts(schemas.path(variant).path(EXTENDS))).as(variant).contains("MatchEventBase"));
    }

    @Test
    void aFeedOfEveryEventTypePassesTheStrictValidator() throws IOException {
        ValidationReport report = validateFeed(feedOf(validExamples()));

        assertThat(report.getMessages()).as("strict validation of a feed with every event type").isEmpty();
    }

    @Test
    void theStrictValidatorRejectsAnUndeclaredEventProperty() throws IOException {
        ArrayNode events = validExamples();
        ((ObjectNode) events.get(0)).put("undeclared", true);

        ValidationReport report = validateFeed(feedOf(events));

        assertThat(report.hasErrors()).isTrue();
        assertThat(report.getMessages()).extracting(ValidationReport.Message::getKey)
                .contains("validation.response.body.schema.oneOf");
    }

    @Test
    void theStrictValidatorRejectsAPayloadThatDoesNotMatchTheType() throws IOException {
        ArrayNode events = validExamples();
        ObjectNode shot = (ObjectNode) findType(events, "SHOT");
        shot.putObject("payload").put("kind", "DEFENSIVE");

        assertThat(validateFeed(feedOf(events)).hasErrors()).isTrue();
    }

    // ------------------------------------------------------------------ helpers

    private static ValidationReport validateFeed(JsonNode feed) {
        return strictGameValidator.validateResponse(FEED_PATH, Request.Method.GET,
                SimpleResponse.Builder.ok().withContentType("application/json").withBody(feed.toString()).build());
    }

    private static ArrayNode validExamples() throws IOException {
        return (ArrayNode) JSON.readTree(ContractFiles.validMatchEventExamples().toFile());
    }

    private static JsonNode findType(ArrayNode events, String type) {
        for (JsonNode event : events) {
            if (type.equals(event.path("type").asText())) {
                return event;
            }
        }
        throw new IllegalStateException("no example of type " + type);
    }

    private static JsonNode feedOf(ArrayNode events) {
        ObjectNode feed = JSON.createObjectNode();
        ArrayNode stored = feed.putArray("events");
        long seq = 0;
        for (JsonNode event : events) {
            ObjectNode entry = stored.addObject();
            entry.put("serverSeq", ++seq);
            entry.set("event", event);
            entry.putObject("recordedBy").put("personId", "0190b6a0-0000-7000-8000-0000000000cc")
                    .put("displayName", "Coach");
            entry.put("receivedAt", "2026-11-01T10:30:00Z");
            entry.putNull("voidedByEventId");
        }
        feed.put("lastServerSeq", seq);
        feed.put("hasMore", false);
        return feed;
    }

    @SuppressWarnings("rawtypes") // swagger-models exposes raw Schema maps
    private static Map<String, Schema> components(String spec) {
        return OpenApiSpecs.parse(spec).getOpenAPI().getComponents().getSchemas();
    }

    /** The spec as a plain tree: x-extends and x-mixins are compared node by node, exactly as written. */
    private static JsonNode yaml(String spec) throws IOException {
        return YAML.readTree(ContractFiles.openApi(spec).toFile());
    }

    private static JsonNode base(JsonNode components, String name) {
        JsonNode schema = components.path("schemas").path(name);
        return schema.isMissingNode() ? components.path(MIXINS).path(name) : schema;
    }

    private static List<String> texts(JsonNode array) {
        List<String> values = new ArrayList<>();
        array.forEach(value -> values.add(value.asText()));
        return values;
    }

    /** {@code {allOf: [<base's $ref>], enum: [...]}}: a variant fixing one value of the base's enum (MatchEvent type). */
    private static boolean narrows(JsonNode copy, JsonNode base) {
        return base.has("$ref") && copy.has("enum") && copy.path("allOf").size() == 1
                && base.get("$ref").equals(copy.path("allOf").get(0).get("$ref"));
    }

    @SuppressWarnings("rawtypes")
    private static Map<String, Schema> properties(Schema<?> schema) {
        return Objects.requireNonNullElse(schema.getProperties(), Map.of());
    }

    /** Every schema node of a spec's components, depth first. */
    @SuppressWarnings("rawtypes")
    private static List<Located> allSchemaNodes(String spec) {
        List<Located> nodes = new ArrayList<>();
        components(spec).forEach((name, schema) -> collect(spec + ":" + name, schema, nodes));
        return nodes;
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static void collect(String location, Schema<?> schema, List<Located> nodes) {
        if (schema == null) {
            return;
        }
        nodes.add(new Located(location, schema));
        properties(schema).forEach((name, property) -> collect(location + "." + name, property, nodes));
        collect(location + "[]", schema.getItems(), nodes);
        if (schema.getAdditionalProperties() instanceof Schema additional) {
            collect(location + "{}", additional, nodes);
        }
        collectAll(location + "/allOf", schema.getAllOf(), nodes);
        collectAll(location + "/oneOf", schema.getOneOf(), nodes);
        collectAll(location + "/anyOf", schema.getAnyOf(), nodes);
    }

    @SuppressWarnings("rawtypes")
    private static void collectAll(String location, Collection<Schema> parts, List<Located> nodes) {
        int index = 0;
        for (Schema part : Objects.requireNonNullElse(parts, List.<Schema>of())) {
            collect(location + "/" + index++, part, nodes);
        }
    }
}
