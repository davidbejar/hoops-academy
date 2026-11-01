package com.hoopsacademy.game.domain.projection;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.game.adapters.json.MatchEventJson;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * Shared test vectors (src/test/resources/vectors, copied to libs/contracts/vectors for the Flutter projector).
 * Each file holds the inputs and the expected projection; this test proves the Java projector reproduces it.
 * Run with {@code -Dvectors.write=true} to (re)write the {@code expected} member of every file in both places
 * after a deliberate projection change, then review the diff.
 */
class ProjectionVectorsTest {

    static final Path VECTORS = Path.of("src/test/resources/vectors");
    static final Path CONTRACT_COPY = Path.of("../../libs/contracts/vectors");
    static final List<String> REQUIRED = List.of("simple-game", "substitutions-and-minutes", "overtime",
            "void-and-corrections", "out-of-order-arrival", "parent-mixed-scorers", "impossible-sequences-warnings");
    static final ObjectMapper JSON = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);

    static Stream<Path> vectorFiles() throws IOException {
        try (Stream<Path> files = Files.list(VECTORS)) {
            return files.filter(f -> f.toString().endsWith(".json")).sorted().toList().stream();
        }
    }

    @Test
    void everyRequiredScenarioHasAVector() throws IOException {
        assertThat(vectorFiles().map(f -> f.getFileName().toString().replace(".json", "")))
                .containsAll(REQUIRED);
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("vectorFiles")
    void projectorReproducesTheVector(Path file) throws IOException {
        ObjectNode vector = (ObjectNode) JSON.readTree(file.toFile());
        JsonNode actual = expectedOf(project(vector));

        if (Boolean.getBoolean("vectors.write")) {
            vector.set("expected", actual);
            String text = JSON.writeValueAsString(vector) + "\n";
            Files.writeString(file, text);
            Files.createDirectories(CONTRACT_COPY);
            Files.writeString(CONTRACT_COPY.resolve(file.getFileName()), text);
        }
        assertThat(actual).isEqualTo(vector.get("expected"));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("vectorFiles")
    void contractCopyIsIdentical(Path file) throws IOException {
        assertThat(CONTRACT_COPY.resolve(file.getFileName())).hasSameTextualContentAs(file);
    }

    static Projection project(JsonNode vector) {
        JsonNode match = vector.get("match");
        MatchRules rules = new MatchRules(match.get("periodCount").asInt(), match.get("periodMinutes").asInt(),
                match.get("overtimeMinutes").asInt());
        List<RosterEntry> roster = stream(vector.get("roster")).map(r -> new RosterEntry(
                PlayerId.of(UUID.fromString(r.get("playerId").asText())), r.get("displayName").asText(),
                JerseyNumber.ofNullable(r.path("jerseyNumber").textValue()), r.get("isStarter").asBoolean())).toList();
        List<RecordedEvent> events = stream(vector.get("events"))
                .map(e -> new RecordedEvent(MatchEventJson.decode(e.get("event")), e.get("serverSeq").asLong()))
                .toList();
        return BoxScoreProjector.project(rules, roster, events);
    }

    /** The comparable form of a projection; warning messages are informative only and left out. */
    static JsonNode expectedOf(Projection projection) {
        ObjectNode expected = JSON.createObjectNode();
        ArrayNode lines = expected.putArray("playerStats");
        for (PlayerLine line : projection.playerStats()) {
            ObjectNode node = lines.addObject().put("playerId", line.playerId().toString()).put("wasStarter", line.wasStarter());
            node.set("stats", JSON.valueToTree(line.stats()));
            node.set("warnings", warnings(line.warnings()));
        }
        MatchSummary summary = projection.summary();
        ObjectNode summaryNode = expected.putObject("summary")
                .put("teamScore", summary.teamScore()).put("opponentScore", summary.opponentScore());
        summaryNode.set("periodScores", JSON.valueToTree(summary.periodScores()));
        summaryNode.put("lastServerSeq", summary.lastServerSeq());
        expected.set("teamTotals", JSON.valueToTree(projection.teamTotals()));
        expected.set("warnings", warnings(projection.warnings()));
        Map<String, String> voided = new TreeMap<>();
        projection.voidedBy().forEach((target, by) -> voided.put(target.toString(), by.toString()));
        expected.set("voidedBy", JSON.valueToTree(voided));
        try {
            return JSON.readTree(JSON.writeValueAsString(expected)); // same number node types as a parsed file
        } catch (IOException e) {
            throw new java.io.UncheckedIOException(e);
        }
    }

    private static ArrayNode warnings(List<ProjectionWarning> warnings) {
        ArrayNode array = JSON.createArrayNode();
        warnings.forEach(w -> array.addObject().put("code", w.code()).put("eventId", w.eventId().toString())
                .put("playerId", w.playerId() == null ? null : w.playerId().toString()));
        return array;
    }

    private static Stream<JsonNode> stream(JsonNode array) {
        return StreamSupport.stream(array.spliterator(), false);
    }
}
