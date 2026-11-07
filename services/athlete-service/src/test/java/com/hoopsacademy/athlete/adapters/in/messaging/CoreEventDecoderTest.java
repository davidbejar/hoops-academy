package com.hoopsacademy.athlete.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent.Invalid;
import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent.Valid;
import com.hoopsacademy.athlete.application.replica.RosterChange;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.athlete.application.replica.RosterTopic;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.io.IOException;
import java.io.InputStream;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Every record of the roster topics is validated against its libs/contracts/events schema before it becomes an event. */
class CoreEventDecoderTest {

    static final ObjectMapper JSON = new ObjectMapper();
    static final TenantId TENANT = TenantId.parse("2b1c4e7a-3f6d-4c1e-9a0b-5d2e8f7c6a10");

    final CoreEventDecoder decoder = new CoreEventDecoder(JSON);

    /** The contract's own examples (libs/contracts/events/examples) as (topic, key, value). */
    static Stream<String[]> contractExamples() throws IOException {
        List<String[]> records = new ArrayList<>();
        for (RosterTopic topic : RosterTopic.values()) {
            try (InputStream in = CoreEventDecoderTest.class.getResourceAsStream(
                    "/events/examples/" + topic.topicName() + ".valid.json")) {
                for (JsonNode event : JSON.readTree(in)) {
                    records.add(new String[] {topic.topicName(),
                            event.get("tenantId").asText() + ":" + event.get("aggregateId").asText(), event.toString()});
                }
            }
        }
        return records.stream();
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("contractExamples")
    void everyContractExampleDecodes(String topic, String key, String value) {
        DecodedEvent decoded = decoder.decode(topic, key, value);

        assertThat(decoded).isNotInstanceOf(DecodedEvent.Invalid.class);
        if (decoded instanceof Valid valid) {
            assertThat(valid.event().topic().topicName()).isEqualTo(topic);
            assertThat(valid.event().tenant()).isEqualTo(TENANT);
        }
    }

    /** WP81: core removes any aggregate now; athlete keeps those rows until WP82 adds their soft removal. */
    /** WP81 publishes a removal for every aggregate; athlete soft-removes all of them (WP82). */
    @ParameterizedTest(name = "{0}")
    @ValueSource(strings = {"core.person", "core.player", "core.team",
            "core.team-player", "core.tenant"})
    void theRemovalsOfPersonsPlayersTeamsAssignmentsAndTenantsCarryTheirIdentity(String topic) throws IOException {
        JsonNode removal = removalExample(topic);

        RosterEvent event = valid(topic, removal);

        assertThat(event.change()).isEqualTo(new RosterChange.Removed(RosterTopic.of(topic).orElseThrow()));
        assertThat(event.topic().topicName()).isEqualTo(topic);
        assertThat(event.eventId()).hasToString(removal.get("eventId").asText());
        assertThat(event.aggregateId()).hasToString(removal.get("aggregateId").asText());
        assertThat(event.occurredAt()).isEqualTo(Instant.parse(removal.get("occurredAt").asText()));
    }

    @Test
    void theRemovalsAthleteAppliesStayValid() throws IOException {
        JsonNode removal = removalExample("core.team-staff");

        assertThat(decoder.decode("core.team-staff",
                removal.get("tenantId").asText() + ":" + removal.get("aggregateId").asText(), removal.toString()))
                .isInstanceOf(Valid.class);
    }

    private static JsonNode removalExample(String topic) throws IOException {
        try (InputStream in = CoreEventDecoderTest.class.getResourceAsStream("/events/examples/" + topic + ".valid.json")) {
            for (JsonNode event : JSON.readTree(in)) {
                if (event.get("type").asText().endsWith(".removed")) {
                    return event;
                }
            }
        }
        throw new IllegalStateException("no removal example for " + topic);
    }

    @Test
    void personEnvelopeAndPayloadAreMapped() throws IOException {
        JsonNode example = example("core.person", 0);

        RosterEvent event = valid("core.person", example);

        assertThat(event.eventId()).isEqualTo(UUID.fromString("0190b6a1-0000-7000-8000-000000000001"));
        assertThat(event.aggregateId()).isEqualTo(UUID.fromString("9f0e1d2c-3b4a-4596-8877-665544332211"));
        assertThat(event.occurredAt()).isEqualTo(Instant.parse("2026-11-06T10:15:30.123456Z"));
        assertThat(event.change()).isEqualTo(new RosterChange.PersonChanged("Cora Coach",
                Optional.of("5c6d7e8f-0a1b-4c2d-8e3f-405162738495"), Set.of(TenantRole.ASSISTANT_COACH, TenantRole.COACH),
                true));
    }

    @Test
    void personWithoutLoginHasNoSubject() throws IOException {
        RosterEvent event = valid("core.person", example("core.person", 1));

        assertThat(((RosterChange.PersonChanged) event.change()).subject()).isEmpty();
        assertThat(((RosterChange.PersonChanged) event.change()).active()).isFalse();
    }

    @Test
    void playerPayloadIsMappedWithOptionalBirthDateAndGender() throws IOException {
        assertThat(valid("core.player", example("core.player", 0)).change()).isEqualTo(new RosterChange.PlayerChanged(
                new PersonId(UUID.fromString("1a2b3c4d-5e6f-4789-9abc-def012345678")), "Pablo Player", "ACTIVE",
                Optional.of(LocalDate.parse("2014-03-09")), Optional.of(Gender.MALE)));
        assertThat(valid("core.player", example("core.player", 1)).change()).isEqualTo(new RosterChange.PlayerChanged(
                new PersonId(UUID.fromString("2b3c4d5e-6f70-4891-8abc-def012345679")), "Paula Pending",
                "PENDING_APPROVAL", Optional.empty(), Optional.empty()));
    }

    @Test
    void teamPayloadKeepsNameSeasonAndItsEnd() throws IOException {
        assertThat(valid("core.team", example("core.team", 0)).change()).isEqualTo(new RosterChange.TeamChanged(
                UUID.fromString("4d5e6f70-8192-4a34-b5c6-d7e8f90a1b2c"), LocalDate.parse("2027-06-30"), "Lions"));
    }

    @Test
    void teamPlayerPayloadIsMapped() throws IOException {
        TeamId team = new TeamId(UUID.fromString("3c4d5e6f-7081-4923-a4b5-c6d7e8f90a1b"));
        assertThat(valid("core.team-player", example("core.team-player", 0)).change()).isEqualTo(
                new RosterChange.TeamPlayerChanged(team, new PlayerId(UUID.fromString("7e6d5c4b-3a29-4180-8f7e-6d5c4b3a2918")),
                        Optional.of("7"), LocalDate.parse("2026-09-15"), Optional.empty(), Optional.empty()));
        assertThat(valid("core.team-player", example("core.team-player", 1)).change()).isEqualTo(
                new RosterChange.TeamPlayerChanged(team, new PlayerId(UUID.fromString("8f7e6d5c-4b3a-4291-9a8b-7c6d5e4f3a2b")),
                        Optional.empty(), LocalDate.parse("2026-09-15"), Optional.of(LocalDate.parse("2026-11-06")),
                        Optional.of("CATEGORY_TOO_LOW")));
    }

    @Test
    void teamStaffChangesAndRemovalsAreDistinguished() throws IOException {
        TeamId team = new TeamId(UUID.fromString("3c4d5e6f-7081-4923-a4b5-c6d7e8f90a1b"));
        PersonId coach = new PersonId(UUID.fromString("9f0e1d2c-3b4a-4596-8877-665544332211"));

        assertThat(valid("core.team-staff", example("core.team-staff", 0)).change())
                .isEqualTo(new RosterChange.TeamStaffChanged(team, coach, "COACH", LocalDate.parse("2026-09-01")));
        assertThat(valid("core.team-staff", example("core.team-staff", 1)).change())
                .isEqualTo(new RosterChange.TeamStaffRemoved(team, coach));
    }

    @Test
    void guardianLinkChangesAndRemovalsAreDistinguished() throws IOException {
        PersonId guardian = new PersonId(UUID.fromString("b4c5d6e7-f809-41a2-b3c4-d5e6f7081920"));
        PlayerId player = new PlayerId(UUID.fromString("7e6d5c4b-3a29-4180-8f7e-6d5c4b3a2918"));

        assertThat(valid("core.guardian-link", example("core.guardian-link", 0)).change())
                .isEqualTo(new RosterChange.GuardianLinkChanged(guardian, player));
        assertThat(valid("core.guardian-link", example("core.guardian-link", 1)).change())
                .isEqualTo(new RosterChange.GuardianLinkRemoved(guardian, player));
    }

    @Test
    void tenantPayloadKeepsStatusAndZone() throws IOException {
        assertThat(valid("core.tenant", example("core.tenant", 1)).change())
                .isEqualTo(new RosterChange.TenantChanged("SUSPENDED", ZoneId.of("Asia/Jakarta")));
    }

    @Test
    void aSchemaViolationIsInvalidWithItsEventIdAndThePathOfTheError() {
        CoreEvents.Record record = CoreEvents.team(TenantId.random(), UUID.randomUUID(), "U12", LocalDate.of(2027, 6, 30));
        String broken = record.value().replace("\"name\":\"U12\"", "\"name\":\"\"");

        DecodedEvent decoded = decoder.decode(record.topic(), record.key(), broken);

        assertThat(decoded).isInstanceOf(Invalid.class);
        assertThat(((Invalid) decoded).eventId()).contains(record.eventId());
        assertThat(((Invalid) decoded).reason()).contains("/payload/name");
    }

    @Test
    void anUnknownFieldIsAViolation() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");

        assertThat(decoder.decode(record.topic(), record.key(), record.value().replace("{\"eventId\"", "{\"extra\":1,\"eventId\"")))
                .isInstanceOf(Invalid.class);
    }

    @Test
    void anotherMajorVersionIsAViolation() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");

        assertThat(decoder.decode(record.topic(), record.key(), record.value().replace("\"version\":1", "\"version\":2")))
                .isInstanceOf(Invalid.class);
    }

    @Test
    void anEventOfAnotherTopicsTypeIsAViolation() {
        CoreEvents.Record team = CoreEvents.team(TenantId.random(), UUID.randomUUID(), "U12", LocalDate.of(2027, 6, 30));

        assertThat(decoder.decode("core.person", team.key(), team.value())).isInstanceOf(Invalid.class);
    }

    @Test
    void aKeyThatDoesNotNameTheEnvelopesTenantAndAggregateIsAViolation() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");
        String otherTenant = TenantId.random() + ":" + record.json().get("aggregateId").asText();

        DecodedEvent decoded = decoder.decode(record.topic(), otherTenant, record.value());

        assertThat(decoded).isInstanceOf(Invalid.class);
        assertThat(((Invalid) decoded).reason()).contains("key");
        assertThat(decoder.decode(record.topic(), null, record.value())).isInstanceOf(Invalid.class);
    }

    @Test
    void aTenantEventAboutAnotherTenantIsAViolation() {
        TenantId tenant = TenantId.random();
        String other = TenantId.random().toString();
        CoreEvents.Record record = CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid");
        String value = record.value().replace("\"aggregateId\":\"" + tenant + "\"", "\"aggregateId\":\"" + other + "\"");

        DecodedEvent decoded = decoder.decode(record.topic(), tenant + ":" + other, value);

        assertThat(decoded).isInstanceOf(Invalid.class);
        assertThat(((Invalid) decoded).reason()).contains("tenant event");
    }

    @Test
    void aTombstoneIsNotAnEvent() {
        assertThat(decoder.decode("core.team-staff", "k", null)).isInstanceOf(Invalid.class);
    }

    @Test
    void malformedJsonIsInvalidWithoutAnEventId() {
        DecodedEvent decoded = decoder.decode("core.person", "k", "{not json");

        assertThat(decoded).isInstanceOf(Invalid.class);
        assertThat(((Invalid) decoded).eventId()).isEmpty();
    }

    @Test
    void anUnknownTopicIsInvalid() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");

        assertThat(decoder.decode("core.unknown", record.key(), record.value())).isInstanceOf(Invalid.class);
    }

    @Test
    void anUnknownTimeZoneIsInvalid() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");

        assertThat(decoder.decode(record.topic(), record.key(), record.value().replace("Europe/Madrid", "Mars/Olympus")))
                .isInstanceOf(Invalid.class);
    }

    @Test
    void aReasonIsBoundedInLength() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");
        String everythingWrong = "{\"" + "a".repeat(300) + "\":1,\"" + "b".repeat(300) + "\":2,\"" + "c".repeat(300) + "\":3}";

        assertThat(((Invalid) decoder.decode(record.topic(), record.key(), everythingWrong)).reason())
                .hasSize(CoreEventDecoder.MAX_REASON_LENGTH);
        assertThat(((Invalid) decoder.decode("core.unknown", record.key(), record.value())).reason())
                .isEqualTo("not a roster topic");
    }

    @Test
    void anEventIdOutsideTheUuidFormatIsNoEventId() {
        CoreEvents.Record record = CoreEvents.tenant(TenantId.random(), "ACTIVE", "Europe/Madrid");
        String value = record.value().replace(record.eventId().toString(), "not-a-uuid");

        DecodedEvent decoded = decoder.decode(record.topic(), record.key(), value);

        assertThat(decoded).isInstanceOfSatisfying(Invalid.class, invalid -> assertThat(invalid.eventId()).isEmpty());
    }

    private RosterEvent valid(String topic, JsonNode event) {
        DecodedEvent decoded = decoder.decode(topic,
                event.get("tenantId").asText() + ":" + event.get("aggregateId").asText(), event.toString());
        assertThat(decoded).isInstanceOf(Valid.class);
        return ((Valid) decoded).event();
    }

    private static JsonNode example(String topic, int index) throws IOException {
        try (InputStream in = CoreEventDecoderTest.class.getResourceAsStream("/events/examples/" + topic + ".valid.json")) {
            return JSON.readTree(in).get(index);
        }
    }
}
