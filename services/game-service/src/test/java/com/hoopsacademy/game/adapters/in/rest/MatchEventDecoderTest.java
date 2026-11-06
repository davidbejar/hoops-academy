package com.hoopsacademy.game.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.game.adapters.json.MatchEventJson;
import com.hoopsacademy.game.application.SubmittedEvent;
import com.hoopsacademy.game.domain.events.MatchEvent;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.UUID;
import java.util.stream.StreamSupport;
import org.assertj.core.api.SoftAssertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/** JSON Schema validation + mapping between the contract's MatchEvent JSON and the domain model. */
class MatchEventDecoderTest {

    static final ObjectMapper JSON = new ObjectMapper();
    final MatchEventDecoder decoder = new MatchEventDecoder(JSON);

    static List<JsonNode> contractExamples() throws IOException {
        try (InputStream in = MatchEventDecoderTest.class.getResourceAsStream("/events/examples/match-events.valid.json")) {
            return StreamSupport.stream(JSON.readTree(in).spliterator(), false).toList();
        }
    }

    private static ObjectNode example(String type) throws IOException {
        return (ObjectNode) contractExamples().stream().filter(e -> e.path("type").asText().equals(type)).findFirst()
                .orElseThrow().deepCopy();
    }

    @ParameterizedTest
    @MethodSource("contractExamples")
    void everyContractExampleDecodesAndEncodesBackToTheSameJson(JsonNode example) throws IOException {
        SubmittedEvent decoded = decoder.decode(example);

        assertThat(decoded).isInstanceOf(SubmittedEvent.Valid.class);
        MatchEvent event = ((SubmittedEvent.Valid) decoded).event();
        assertThat(event.type().name()).isEqualTo(example.path("type").asText());
        assertThat(JSON.readTree(JSON.writeValueAsString(MatchEventJson.encode(JSON, event)))).isEqualTo(example);
    }

    @Test
    void schemaViolationIsInvalidWithTheEventIdAndTheFailingPath() throws IOException {
        ObjectNode shot = example("SHOT");
        ((ObjectNode) shot.get("payload")).remove("points");

        SubmittedEvent decoded = decoder.decode(shot);

        assertThat(decoded).isInstanceOf(SubmittedEvent.Invalid.class);
        assertThat(decoded.eventId()).isEqualTo(UUID.fromString(shot.get("id").asText()));
        assertThat(((SubmittedEvent.Invalid) decoded).message()).contains("points");
    }

    /**
     * The exact wording of {@code results[].message} for typical schema violations (client-facing text). Pinned so a
     * validator upgrade cannot change it silently (WP43, json-schema-validator 2.x to 3.x).
     */
    @Test
    void schemaViolationMessagesKeepTheirWording() throws IOException {
        ObjectNode noPoints = example("SHOT");
        ((ObjectNode) noPoints.get("payload")).remove("points");
        ObjectNode fourPoints = example("SHOT");
        ((ObjectNode) fourPoints.get("payload")).put("points", 4);
        ObjectNode noPlayer = example("REBOUND");
        noPlayer.remove("playerId");
        ObjectNode noSequence = example("PERIOD_START");
        noSequence.remove("clientSeq");
        SoftAssertions soft = new SoftAssertions();

        soft.assertThat(messageOf(noPoints)).isEqualTo("/payload: required property 'points' not found");
        soft.assertThat(messageOf(fourPoints)).isEqualTo("/payload/points: does not have a value in the enumeration [1, 2, 3]");
        soft.assertThat(messageOf(example("SHOT").put("type", "DUNK"))).isEqualTo("/type: does not have a value in the enumeration"
                + " [\"PERIOD_START\", \"PERIOD_END\", \"SUB_IN\", \"SUB_OUT\", \"SHOT\", \"ASSIST\", \"REBOUND\", \"TURNOVER\","
                + " \"STEAL\", \"BLOCK\", \"FOUL\", \"OPPONENT_SCORE\", \"TIMEOUT\", \"VOID\", \"NOTE\"]");
        soft.assertThat(messageOf(noPlayer)).isEqualTo(": required property 'playerId' not found");
        soft.assertThat(messageOf(noSequence))
                .isEqualTo(": required property 'clientSeq' not found; : required property 'clientSeq' not found");
        soft.assertThat(messageOf(example("ASSIST").put("clientSeq", "seven")))
                .isEqualTo("/clientSeq: string found, integer expected; /clientSeq: string found, integer expected");
        soft.assertAll();
    }

    private String messageOf(JsonNode event) {
        return ((SubmittedEvent.Invalid) decoder.decode(event)).message();
    }

    @Test
    void eventWithoutAUsableIdIsInvalidWithTheNilUuid() throws IOException {
        ObjectNode shot = example("SHOT").put("id", "not-a-uuid");

        assertThat(decoder.decode(shot).eventId()).isEqualTo(new UUID(0, 0));
        assertThat(decoder.decode(JSON.getNodeFactory().textNode("x")).eventId()).isEqualTo(new UUID(0, 0));
    }

    @Test
    void malformedTimestampIsInvalid() throws IOException {
        ObjectNode shot = example("SHOT").put("recordedAtClient", "yesterday");

        assertThat(decoder.decode(shot)).isInstanceOf(SubmittedEvent.Invalid.class);
    }

    @Test
    void unknownTypeIsInvalid() throws IOException {
        assertThat(decoder.decode(example("SHOT").put("type", "DUNK"))).isInstanceOf(SubmittedEvent.Invalid.class);
    }
}
