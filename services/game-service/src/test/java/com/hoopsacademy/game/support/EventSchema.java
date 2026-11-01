package com.hoopsacademy.game.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.time.OffsetDateTime;
import java.util.UUID;

/** Validates events returned by the API against libs/contracts events/match-event.schema.json. */
public final class EventSchema {

    private static final Schema SCHEMA = load();

    private EventSchema() {}

    /**
     * A MatchEventFeed body matches the contract: the envelope (required members and their types) and every
     * {@code events[].event} against the MatchEvent JSON Schema.
     */
    public static void assertValidFeed(String feedBody) {
        try {
            JsonNode feed = EventBatches.JSON.readTree(feedBody);
            assertThat(feed.get("lastServerSeq").isIntegralNumber()).isTrue();
            assertThat(feed.get("lastServerSeq").asLong()).isNotNegative();
            assertThat(feed.get("hasMore").isBoolean()).isTrue();
            assertThat(feed.get("events").isArray()).isTrue();
            feed.get("events").forEach(EventSchema::assertValidStoredEvent);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static void assertValidStoredEvent(JsonNode stored) {
        assertThat(stored.get("serverSeq").asLong()).as("serverSeq").isPositive();
        assertThat(UUID.fromString(stored.at("/recordedBy/personId").asText())).isNotNull();
        assertThat(stored.at("/recordedBy/displayName").isTextual()).as("recordedBy.displayName").isTrue();
        assertThat(OffsetDateTime.parse(stored.get("receivedAt").asText())).isNotNull();
        JsonNode voided = stored.get("voidedByEventId");
        assertThat(voided == null || voided.isNull() || UUID.fromString(voided.asText()) != null).isTrue();
        assertThat(SCHEMA.validate(stored.get("event"))).as(stored.toString()).isEmpty();
    }

    private static Schema load() {
        try (InputStream in = EventSchema.class.getResourceAsStream("/events/match-event.schema.json")) {
            return SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12).getSchema(EventBatches.JSON.readTree(in));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
