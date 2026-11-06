package com.hoopsacademy.contracts;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaLocation;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * The core roster event contracts ({@code events/core.<aggregate>.schema.json}, WP67, ADR-0036): one JSON Schema
 * 2020-12 per topic, the same envelope in every file, valid examples for every event type, and the naming rules of
 * the README section "Events".
 */
class CoreEventSchemasTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final String META_SCHEMA_2020_12 = "https://json-schema.org/draft/2020-12/schema";
    private static final Pattern TOPIC = Pattern.compile("^core\\.([a-z]+(?:-[a-z]+)*)(?:\\.v([2-9]|[1-9][0-9]+))?$");
    private static final Pattern CAMEL_CASE = Pattern.compile("^[a-z][a-zA-Z0-9]*$");
    private static final List<String> ENVELOPE = List.of("eventId", "type", "version", "tenantId", "aggregateId",
            "occurredAt", "payload");
    private static final SchemaRegistry REGISTRY = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);

    static Stream<String> topics() {
        return schemaFiles().map(file -> file.getFileName().toString().replace(".schema.json", ""));
    }

    static Stream<Arguments> examples() {
        return topics().flatMap(topic -> StreamSupport.stream(examplesOf(topic).spliterator(), false)
                .map(example -> Arguments.of(topic, example)));
    }

    @Test
    void thereIsOneSchemaPerBrokerTopic() throws IOException {
        String script = Files.readString(ContractFiles.moduleDir().resolve("../../infra/compose/redpanda-topics.sh"));
        Matcher declared = Pattern.compile("(?m)^TOPICS=\\((.*)\\)$").matcher(script);
        assertThat(declared.find()).as("TOPICS=(…) in infra/compose/redpanda-topics.sh").isTrue();

        assertThat(topics().toList()).containsExactlyInAnyOrder(declared.group(1).trim().split("\\s+"));
    }

    @ParameterizedTest
    @MethodSource("topics")
    void schemaIsValidDraft202012AndNamedAfterItsTopic(String topic) {
        JsonNode schema = schema(topic);
        Schema metaSchema = REGISTRY.getSchema(SchemaLocation.of(META_SCHEMA_2020_12));

        assertThat(metaSchema.validate(schema)).isEmpty();
        assertThat(schema.path("$schema").asText()).isEqualTo(META_SCHEMA_2020_12);
        assertThat(schema.path("$id").asText()).endsWith("/events/" + topic + ".schema.json");
        assertThat(schema.path("title").asText()).isEqualTo(topic);
        assertThat(TOPIC.matcher(topic).matches()).as("topic name %s", topic).isTrue();
    }

    @ParameterizedTest
    @MethodSource("topics")
    void everyTopicHasTheSameEnvelope(String topic) {
        JsonNode schema = schema(topic);
        JsonNode reference = schema("core.person");

        assertThat(fieldNames(schema.path("properties"))).containsExactlyElementsOf(ENVELOPE);
        assertThat(strings(schema.path("required"))).containsExactlyElementsOf(ENVELOPE);
        assertThat(schema.path("additionalProperties").asBoolean(true)).isFalse();
        for (String field : List.of("eventId", "tenantId", "aggregateId", "occurredAt")) {
            assertThat(schema.at("/properties/" + field)).as(field).isEqualTo(reference.at("/properties/" + field));
        }
        assertThat(schema.at("/$defs/Uuid")).isEqualTo(reference.at("/$defs/Uuid"));
        assertThat(schema.at("/$defs/Instant")).isEqualTo(reference.at("/$defs/Instant"));
    }

    @ParameterizedTest
    @MethodSource("topics")
    void typesAreAggregateDotVerbAndTheVersionFollowsTheTopicSuffix(String topic) {
        Matcher name = TOPIC.matcher(topic);
        assertThat(name.matches()).isTrue();
        String aggregate = name.group(1);
        int version = name.group(2) == null ? 1 : Integer.parseInt(name.group(2));
        JsonNode schema = schema(topic);

        List<String> types = strings(schema.at("/properties/type/enum"));
        assertThat(types).contains(aggregate + ".changed")
                .allMatch(type -> type.equals(aggregate + ".changed") || type.equals(aggregate + ".removed"));
        assertThat(schema.at("/properties/version/const").asInt()).isEqualTo(version);
        for (String type : types) {
            String payload = pascal(aggregate) + pascal(type.substring(type.indexOf('.') + 1));
            assertThat(schema.at("/$defs/" + payload).isObject()).as("$defs/%s for %s", payload, type).isTrue();
        }
    }

    @ParameterizedTest
    @MethodSource("topics")
    void payloadsAreClosedCamelCaseObjectsWithEveryFieldRequired(String topic) {
        JsonNode defs = schema(topic).path("$defs");
        for (String name : fieldNames(defs)) {
            if (!name.endsWith("Changed") && !name.endsWith("Removed")) {
                continue;
            }
            JsonNode payload = defs.path(name);
            assertThat(payload.path("type").asText()).as(name).isEqualTo("object");
            assertThat(payload.path("additionalProperties").asBoolean(true)).as(name).isFalse();
            assertThat(new TreeSet<>(strings(payload.path("required"))))
                    .as("%s: every field is required (an absent value is an explicit null)", name)
                    .isEqualTo(new TreeSet<>(fieldNames(payload.path("properties"))));
            assertThat(fieldNames(payload.path("properties"))).as(name).allMatch(f -> CAMEL_CASE.matcher(f).matches());
        }
    }

    @ParameterizedTest
    @MethodSource("topics")
    void examplesCoverEveryTypeOfTheTopic(String topic) {
        Set<String> exampleTypes = new TreeSet<>();
        examplesOf(topic).forEach(example -> exampleTypes.add(example.path("type").asText()));

        assertThat(exampleTypes).containsExactlyInAnyOrderElementsOf(strings(schema(topic).at("/properties/type/enum")));
    }

    @ParameterizedTest(name = "{0} {1}")
    @MethodSource("examples")
    void examplesAreValid(String topic, JsonNode example) {
        assertThat(validate(topic, example)).isEmpty();
    }

    @ParameterizedTest
    @MethodSource("topics")
    void rejectsAnUnknownEnvelopeFieldATenantThatIsNoUuidAndAMissingPayloadField(String topic) {
        ObjectNode extra = changedExample(topic);
        extra.put("partition", 0);
        ObjectNode tenant = changedExample(topic);
        tenant.put("tenantId", "academy-a");
        ObjectNode missing = changedExample(topic);
        String first = ((ObjectNode) missing.get("payload")).fieldNames().next();
        ((ObjectNode) missing.get("payload")).remove(first);
        ObjectNode local = changedExample(topic);
        local.put("occurredAt", "2026-11-06T10:15:30+01:00");

        assertThat(validate(topic, extra)).isNotEmpty();
        assertThat(validate(topic, tenant)).isNotEmpty();
        assertThat(validate(topic, missing)).as("without %s", first).isNotEmpty();
        assertThat(validate(topic, local)).as("occurredAt is UTC").isNotEmpty();
    }

    @ParameterizedTest
    @MethodSource("topics")
    void rejectsATypeOfAnotherTopicAndAnotherVersion(String topic) {
        ObjectNode foreign = changedExample(topic);
        foreign.put("type", topic.equals("core.team") ? "person.changed" : "team.changed");
        ObjectNode version = changedExample(topic);
        version.put("version", 2);

        assertThat(validate(topic, foreign)).isNotEmpty();
        assertThat(validate(topic, version)).isNotEmpty();
    }

    @Test
    void aRemovedEventCarriesTheIdentityOnlyAndAChangedEventTheFullState() {
        for (String topic : List.of("core.team-staff", "core.guardian-link")) {
            ObjectNode removed = example(topic, ".removed");
            ObjectNode changed = example(topic, ".changed");
            removed.set("payload", changed.get("payload"));
            changed.put("type", removed.get("type").asText());

            if (topic.equals("core.team-staff")) {
                assertThat(validate(topic, changed)).as("%s removed with the full state", topic).isNotEmpty();
            }
            assertThat(validate(topic, example(topic, ".removed"))).isEmpty();
        }
        ObjectNode person = example("core.person", ".changed");
        person.put("type", "person.removed");
        assertThat(validate("core.person", person)).as("persons are never removed").isNotEmpty();
    }

    @Test
    void theTenantEventIsKeyedByTheTenantItself() {
        examplesOf("core.tenant").forEach(example ->
                assertThat(example.path("aggregateId")).isEqualTo(example.path("tenantId")));
    }

    @Test
    void nullableFieldsAcceptNull() {
        ObjectNode player = example("core.player", ".changed");
        ((ObjectNode) player.get("payload")).putNull("birthDate").putNull("gender");
        ObjectNode person = example("core.person", ".changed");
        ((ObjectNode) person.get("payload")).putNull("subject");
        ObjectNode name = example("core.person", ".changed");
        ((ObjectNode) name.get("payload")).putNull("displayName");

        assertThat(validate("core.player", player)).isEmpty();
        assertThat(validate("core.person", person)).isEmpty();
        assertThat(validate("core.person", name)).as("displayName is not nullable").isNotEmpty();
    }

    private static List<Error> validate(String topic, JsonNode event) {
        return REGISTRY.getSchema(schema(topic)).validate(event);
    }

    private static ObjectNode changedExample(String topic) {
        return example(topic, ".changed");
    }

    private static ObjectNode example(String topic, String verb) {
        for (JsonNode example : examplesOf(topic)) {
            if (example.path("type").asText().endsWith(verb)) {
                return example.deepCopy();
            }
        }
        throw new IllegalStateException("no " + verb + " example for " + topic);
    }

    private static Stream<Path> schemaFiles() {
        try (Stream<Path> files = Files.list(ContractFiles.moduleDir().resolve("events"))) {
            return files.filter(file -> file.getFileName().toString().startsWith("core."))
                    .filter(file -> file.getFileName().toString().endsWith(".schema.json")).sorted().toList().stream();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static JsonNode schema(String topic) {
        return read(ContractFiles.moduleDir().resolve("events").resolve(topic + ".schema.json"));
    }

    private static JsonNode examplesOf(String topic) {
        return read(ContractFiles.moduleDir().resolve("events").resolve("examples").resolve(topic + ".valid.json"));
    }

    private static JsonNode read(Path file) {
        try {
            return JSON.readTree(file.toFile());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static List<String> fieldNames(JsonNode node) {
        List<String> names = new ArrayList<>();
        node.fieldNames().forEachRemaining(names::add);
        return names;
    }

    private static List<String> strings(JsonNode array) {
        return StreamSupport.stream(array.spliterator(), false).map(JsonNode::asText).toList();
    }

    private static String pascal(String kebab) {
        return Arrays.stream(kebab.split("-")).map(part -> Character.toUpperCase(part.charAt(0)) + part.substring(1))
                .reduce("", String::concat);
    }
}
