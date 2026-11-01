package com.hoopsacademy.contracts;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaLocation;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

import java.io.IOException;
import java.util.List;
import java.util.stream.StreamSupport;

import static org.assertj.core.api.Assertions.assertThat;

/** Behaviour of events/match-event.schema.json (JSON Schema 2020-12). */
class MatchEventJsonSchemaTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final String META_SCHEMA_2020_12 = "https://json-schema.org/draft/2020-12/schema";

    private static SchemaRegistry registry;
    private static JsonNode schemaDocument;
    private static Schema matchEventSchema;

    @BeforeAll
    static void loadSchema() throws IOException {
        registry = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);
        schemaDocument = JSON.readTree(ContractFiles.matchEventSchema().toFile());
        matchEventSchema = registry.getSchema(schemaDocument);
    }

    static List<JsonNode> validExamples() throws IOException {
        JsonNode examples = JSON.readTree(ContractFiles.validMatchEventExamples().toFile());
        return StreamSupport.stream(examples.spliterator(), false).toList();
    }

    @Test
    void schemaIsValidAgainstTheDraft202012MetaSchema() {
        Schema metaSchema = registry.getSchema(SchemaLocation.of(META_SCHEMA_2020_12));

        assertThat(metaSchema.validate(schemaDocument)).isEmpty();
        assertThat(schemaDocument.path("$schema").asText()).isEqualTo(META_SCHEMA_2020_12);
    }

    @Test
    void examplesCoverEveryEventType() throws IOException {
        List<String> exampleTypes = validExamples().stream().map(e -> e.path("type").asText()).distinct().toList();
        List<String> declaredTypes = StreamSupport.stream(
                schemaDocument.at("/$defs/MatchEventType/enum").spliterator(), false).map(JsonNode::asText).toList();

        assertThat(exampleTypes).containsExactlyInAnyOrderElementsOf(declaredTypes);
    }

    @ParameterizedTest
    @MethodSource("validExamples")
    void acceptsValidEvent(JsonNode event) {
        assertThat(matchEventSchema.validate(event)).as(event.path("type").asText()).isEmpty();
    }

    @Test
    void rejectsUnknownType() {
        ObjectNode event = example("SHOT").put("type", "DUNK_CONTEST");

        assertThat(matchEventSchema.validate(event))
                .anyMatch(e -> e.getInstanceLocation().toString().endsWith("type") && e.getMessage().contains("enum"));
    }

    @Test
    void rejectsShotWithoutPoints() {
        ObjectNode event = example("SHOT");
        ((ObjectNode) event.get("payload")).remove("points");

        assertThat(messages(matchEventSchema.validate(event))).anyMatch(m -> m.contains("points"));
    }

    @Test
    void rejectsShotWithInvalidPoints() {
        ObjectNode event = example("SHOT");
        ((ObjectNode) event.get("payload")).put("points", 4);

        assertThat(matchEventSchema.validate(event)).isNotEmpty();
    }

    @Test
    void rejectsShotWithoutPayload() {
        ObjectNode event = example("SHOT");
        event.remove("payload");

        assertThat(messages(matchEventSchema.validate(event))).anyMatch(m -> m.contains("payload"));
    }

    @Test
    void rejectsPlayerStatEventWithoutPlayer() {
        ObjectNode event = example("REBOUND");
        event.remove("playerId");

        assertThat(messages(matchEventSchema.validate(event))).anyMatch(m -> m.contains("playerId"));
    }

    @Test
    void rejectsVoidWithoutTarget() {
        ObjectNode event = example("VOID");
        ((ObjectNode) event.get("payload")).remove("targetEventId");

        assertThat(messages(matchEventSchema.validate(event))).anyMatch(m -> m.contains("targetEventId"));
    }

    @Test
    void rejectsMalformedEventId() {
        ObjectNode event = example("ASSIST").put("id", "not-a-uuid");

        assertThat(matchEventSchema.validate(event)).isNotEmpty();
    }

    @Test
    void rejectsEventWithoutClientSequence() {
        ObjectNode event = example("PERIOD_START");
        event.remove("clientSeq");

        assertThat(messages(matchEventSchema.validate(event))).anyMatch(m -> m.contains("clientSeq"));
    }

    private static ObjectNode example(String type) {
        try {
            return validExamples().stream()
                    .filter(e -> e.path("type").asText().equals(type))
                    .findFirst()
                    .map(e -> (ObjectNode) e.deepCopy())
                    .orElseThrow(() -> new IllegalStateException("no example for " + type));
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    private static List<String> messages(List<Error> errors) {
        return errors.stream().map(Error::getMessage).toList();
    }
}
