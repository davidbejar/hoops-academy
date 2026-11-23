package com.hoopsacademy.common.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.common.replica.DecodedEvent.Invalid;
import com.hoopsacademy.common.replica.DecodedEvent.Valid;
import com.hoopsacademy.common.tenancy.TenantId;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.time.DateTimeException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * The envelope half of the core event decoders (WP130, ADR-0062): the topic's JSON Schema from the contracts jar, the
 * key {@code <tenantId>:<aggregateId>}, a tenant event about its own tenant, a bounded reason without the record's
 * values. The service's mapper sees only valid envelopes; what it cannot read is parked, not thrown.
 */
class CoreEventDecoderTest {

    private static final ObjectMapper JSON = new ObjectMapper();

    /** What the test mapper hands back: everything the decoder gave it. */
    record Mapped(RosterTopic topic, EventEnvelope envelope, String type, JsonNode payload) {}

    private final CoreEventDecoder<Mapped> decoder = new CoreEventDecoder<>(JSON, Mapped::new);

    static Stream<JsonNode> contractExamples() {
        List<JsonNode> events = new ArrayList<>();
        for (RosterTopic topic : RosterTopic.values()) {
            examples(topic).forEach(events::add);
        }
        return events.stream();
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("contractExamples")
    void everyContractExampleIsValidAndItsEnvelopeReachesTheMapper(JsonNode event) {
        RosterTopic topic = RosterTopic.of(topicOf(event.get("type").asText())).orElseThrow();

        Valid<Mapped> valid = valid(decoder.decode(topic.topicName(), keyOf(event), event.toString()));

        EventEnvelope envelope = new EventEnvelope(UUID.fromString(event.get("eventId").asText()),
                TenantId.parse(event.get("tenantId").asText()), UUID.fromString(event.get("aggregateId").asText()),
                Instant.parse(event.get("occurredAt").asText()));
        assertThat(valid.envelope()).isEqualTo(envelope);
        assertThat(valid.event()).isEqualTo(new Mapped(topic, envelope, event.get("type").asText(), event.get("payload")));
    }

    @Test
    void anUnknownTopicIsInvalidWithoutNamingIt() {
        JsonNode event = example(RosterTopic.TEAM);

        Invalid<Mapped> invalid = invalid(decoder.decode("core.unknown", keyOf(event), event.toString()));

        assertThat(invalid.reason()).isEqualTo("not a roster topic");
        assertThat(invalid.eventId()).isEmpty();
    }

    @Test
    void aRecordWithoutValueIsInvalid() {
        assertThat(invalid(decoder.decode("core.team", "k", null)).reason()).isEqualTo("no value");
    }

    @Test
    void malformedJsonIsInvalidWithoutQuotingIt() {
        Invalid<Mapped> invalid = invalid(decoder.decode("core.team", "k", "{\"secret\": tru"));

        assertThat(invalid.reason()).isEqualTo("value is not JSON");
        assertThat(invalid.eventId()).isEmpty();
    }

    @Test
    void aSchemaViolationKeepsTheEventIdAndThePathOfTheError() {
        ObjectNode event = example(RosterTopic.TEAM).deepCopy();
        ((ObjectNode) event.get("payload")).put("name", 42);

        Invalid<Mapped> invalid = invalid(decoder.decode("core.team", keyOf(event), event.toString()));

        assertThat(invalid.eventId()).contains(UUID.fromString(event.get("eventId").asText()));
        assertThat(invalid.reason()).contains("/payload/name");
    }

    @Test
    void anEventOfAnotherTopicsContractIsAViolation() {
        JsonNode person = example(RosterTopic.PERSON);

        assertThat(decoder.decode("core.team", keyOf(person), person.toString())).isInstanceOf(Invalid.class);
    }

    @Test
    void atMostFiveSchemaErrorsAreKept() {
        ObjectNode event = example(RosterTopic.TEAM).deepCopy();
        for (int i = 0; i < 8; i++) {
            event.put("x" + i, i);
        }

        Invalid<Mapped> invalid = invalid(decoder.decode("core.team", keyOf(event), event.toString()));

        assertThat(invalid.reason().split("; ")).hasSize(CoreEventDecoder.MAX_ERRORS);
    }

    @Test
    void aReasonIsBoundedInLength() {
        String everythingWrong = "{\"" + "a".repeat(300) + "\":1,\"" + "b".repeat(300) + "\":2}";

        Invalid<Mapped> invalid = invalid(decoder.decode("core.team", "k", everythingWrong));

        assertThat(invalid.reason()).hasSize(CoreEventDecoder.MAX_REASON_LENGTH);
    }

    @Test
    void theKeyMustNameTheEnvelopesTenantAndAggregateAndTheReasonDoesNotRepeatIt() {
        JsonNode event = example(RosterTopic.TEAM);
        String otherTenant = TenantId.random() + ":" + event.get("aggregateId").asText();

        Invalid<Mapped> invalid = invalid(decoder.decode("core.team", otherTenant, event.toString()));

        assertThat(invalid.reason()).isEqualTo("key is not <tenantId>:<aggregateId> of the envelope")
                .doesNotContain(otherTenant);
        assertThat(invalid.eventId()).contains(UUID.fromString(event.get("eventId").asText()));
        assertThat(decoder.decode("core.team", null, event.toString())).isInstanceOf(Invalid.class);
    }

    @Test
    void aTenantEventMustBeAboutItsOwnTenant() {
        ObjectNode event = example(RosterTopic.TENANT).deepCopy();
        event.put("aggregateId", UUID.randomUUID().toString());

        Invalid<Mapped> invalid = invalid(decoder.decode("core.tenant", keyOf(event), event.toString()));

        assertThat(invalid.reason()).isEqualTo("a tenant event's aggregateId is not its tenantId");
    }

    @Test
    void anotherTopicsAggregateIsNotItsTenant() {
        JsonNode event = example(RosterTopic.TEAM);

        assertThat(event.get("aggregateId")).isNotEqualTo(event.get("tenantId"));
        assertThat(decoder.decode("core.team", keyOf(event), event.toString())).isInstanceOf(Valid.class);
    }

    @ParameterizedTest
    @EnumSource(value = Unreadable.class)
    void aValueTheMapperCannotReadIsInvalidAndNamesOnlyTheKindOfFailure(Unreadable failure) {
        CoreEventDecoder<Mapped> failing = new CoreEventDecoder<>(JSON, (topic, envelope, type, payload) -> {
            throw failure.exception;
        });
        JsonNode event = example(RosterTopic.TENANT);

        Invalid<Mapped> invalid = invalid(failing.decode("core.tenant", keyOf(event), event.toString()));

        assertThat(invalid.reason()).isEqualTo("value outside the contract: " + failure.exception.getClass().getSimpleName())
                .doesNotContain("Mars");
        assertThat(invalid.eventId()).contains(UUID.fromString(event.get("eventId").asText()));
    }

    enum Unreadable {
        ARGUMENT(new IllegalArgumentException("Mars/Olympus")),
        DATE_TIME(new DateTimeException("Mars/Olympus"));

        final RuntimeException exception;

        Unreadable(RuntimeException exception) {
            this.exception = exception;
        }
    }

    @Test
    void anyOtherMapperFailureIsABugAndIsNotParked() {
        CoreEventDecoder<Mapped> broken = new CoreEventDecoder<>(JSON, (topic, envelope, type, payload) -> {
            throw new IllegalStateException("bug");
        });
        JsonNode event = example(RosterTopic.TEAM);

        assertThatThrownBy(() -> broken.decode("core.team", keyOf(event), event.toString())).hasMessage("bug");
    }

    @Test
    void anEventIdOutsideTheUuidFormatIsNoEventId() {
        ObjectNode event = example(RosterTopic.TEAM).deepCopy();
        event.put("eventId", "0190B6A1-0000-7000-8000-000000000061");
        assertThat(invalid(decoder.decode("core.team", keyOf(event), event.toString())).eventId()).isEmpty();

        event.put("eventId", 42);
        assertThat(invalid(decoder.decode("core.team", keyOf(event), event.toString())).eventId()).isEmpty();
    }

    @Test
    void aDecoderWithoutTheContractsOnItsClassPathFailsAtOnce() {
        assertThatThrownBy(() -> new CoreEventDecoder<>(JSON, Mapped::new, "/no-such-folder/"))
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("/no-such-folder/core.person.schema.json");
    }

    private static <E> Valid<E> valid(DecodedEvent<E> decoded) {
        assertThat(decoded).isInstanceOf(Valid.class);
        return (Valid<E>) decoded;
    }

    private static <E> Invalid<E> invalid(DecodedEvent<E> decoded) {
        assertThat(decoded).isInstanceOf(Invalid.class);
        return (Invalid<E>) decoded;
    }

    private static String keyOf(JsonNode event) {
        return event.get("tenantId").asText() + ":" + event.get("aggregateId").asText();
    }

    private static String topicOf(String type) {
        return "core." + type.substring(0, type.indexOf('.'));
    }

    static JsonNode example(RosterTopic topic) {
        return examples(topic).getFirst();
    }

    static List<JsonNode> examples(RosterTopic topic) {
        try (InputStream in = CoreEventDecoderTest.class.getResourceAsStream(
                "/events/examples/" + topic.topicName() + ".valid.json")) {
            List<JsonNode> events = new ArrayList<>();
            JSON.readTree(in).forEach(events::add);
            return events;
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
