package com.hoopsacademy.game.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder.Decoded;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.application.replica.RosterEvent.GuardianLinkChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.GuardianLinkRemoved;
import com.hoopsacademy.game.application.replica.RosterEvent.PersonChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.PlayerChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.Removed;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamPlayerChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamStaffChanged;
import com.hoopsacademy.game.application.replica.RosterEvent.TeamStaffRemoved;
import com.hoopsacademy.game.application.replica.RosterEvent.TenantChanged;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Records of the core.* topics become typed roster events only when they match the topic's contract
 * (libs/contracts/events, read from the contracts jar) and their key is {@code <tenantId>:<aggregateId>}; anything
 * else is a rejection with a reason (the consumer parks it).
 */
class RosterEventDecoderTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final TenantId TENANT = TenantId.parse("2b1c4e7a-3f6d-4c1e-9a0b-5d2e8f7c6a10");

    private final RosterEventDecoder decoder = new RosterEventDecoder();

    @Test
    void everyContractExampleDecodes() {
        for (String topic : List.of("core.person", "core.player", "core.team", "core.team-player", "core.team-staff",
                "core.guardian-link", "core.tenant")) {
            for (JsonNode example : examples(topic)) {
                assertThat(decode(topic, example)).as(topic + " " + example).isNotInstanceOf(Decoded.Invalid.class);
            }
        }
    }

    /** WP81 publishes a removal for every aggregate; game soft-removes all of them (WP82). */
    @Test
    void theRemovalsOfPersonsPlayersTeamsAssignmentsAndTenantsCarryTheirIdentity() {
        Map<String, RosterEvent.Aggregate> aggregates = Map.of("core.person", RosterEvent.Aggregate.PERSON,
                "core.player", RosterEvent.Aggregate.PLAYER, "core.team", RosterEvent.Aggregate.TEAM,
                "core.team-player", RosterEvent.Aggregate.TEAM_PLAYER, "core.tenant", RosterEvent.Aggregate.TENANT);
        aggregates.forEach((topic, aggregate) -> {
            JsonNode removal = examples(topic).stream().filter(e -> e.get("type").asText().endsWith(".removed"))
                    .findFirst().orElseThrow();

            Decoded decoded = decode(topic, removal);

            assertThat(decoded).as(topic).isInstanceOfSatisfying(Decoded.Valid.class, valid ->
                    assertThat(valid.event()).isInstanceOfSatisfying(Removed.class, removed -> {
                        assertThat(removed.aggregate()).isEqualTo(aggregate);
                        assertThat(removed.topic()).isEqualTo(topic);
                        assertThat(removed.envelope().eventId().toString()).isEqualTo(removal.get("eventId").asText());
                        assertThat(removed.envelope().aggregateId().toString())
                                .isEqualTo(removal.get("aggregateId").asText());
                        assertThat(removed.envelope().tenantId()).isEqualTo(TENANT);
                    }));
        });
    }

    @Test
    void aTenantRemovalAboutAnotherTenantIsInvalid() {
        ObjectNode removal = examples("core.tenant").stream().filter(e -> e.get("type").asText().endsWith(".removed"))
                .findFirst().orElseThrow().deepCopy();
        String other = UUID.randomUUID().toString();
        removal.put("aggregateId", other);

        Decoded decoded = decoder.decode("core.tenant", TENANT + ":" + other, removal.toString());

        assertThat(decoded).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.reason()).contains("own tenant"));
    }

    @Test
    void personCarriesNameLoginRolesAndActivity() {
        PersonChanged cora = (PersonChanged) event("core.person", 0);
        assertThat(cora.envelope().eventId()).isEqualTo(UUID.fromString("0190b6a1-0000-7000-8000-000000000001"));
        assertThat(cora.envelope().tenantId()).isEqualTo(TENANT);
        assertThat(cora.envelope().aggregateId()).isEqualTo(UUID.fromString("9f0e1d2c-3b4a-4596-8877-665544332211"));
        assertThat(cora.envelope().occurredAt()).isEqualTo(Instant.parse("2026-11-06T10:15:30.123456Z"));
        assertThat(cora.displayName()).isEqualTo("Cora Coach");
        assertThat(cora.subject()).contains("5c6d7e8f-0a1b-4c2d-8e3f-405162738495");
        assertThat(cora.roles()).isEqualTo(Set.of(TenantRole.ASSISTANT_COACH, TenantRole.COACH));
        assertThat(cora.active()).isTrue();

        PersonChanged pablo = (PersonChanged) event("core.person", 1);
        assertThat(pablo.subject()).isEmpty();
        assertThat(pablo.active()).isFalse();
    }

    @Test
    void playerTeamAndAssignmentCarryWhatTheRosterNeeds() {
        JsonNode playerJson = examples("core.player").getFirst();
        PlayerChanged player = (PlayerChanged) event("core.player", 0);
        assertThat(player.personId()).isEqualTo(UUID.fromString(playerJson.at("/payload/personId").asText()));
        assertThat(player.displayName()).isEqualTo(playerJson.at("/payload/displayName").asText());
        assertThat(player.status()).isEqualTo(playerJson.at("/payload/status").asText());
        assertThat(player.birthDate().map(LocalDate::toString)).isEqualTo(text(playerJson, "/payload/birthDate"));
        assertThat(player.gender()).isEqualTo(text(playerJson, "/payload/gender"));

        TeamChanged lions = (TeamChanged) event("core.team", 0);
        assertThat(lions.seasonId()).isEqualTo(SeasonId.of(UUID.fromString("4d5e6f70-8192-4a34-b5c6-d7e8f90a1b2c")));
        assertThat(lions.seasonEndDate()).isEqualTo(LocalDate.parse("2027-06-30"));
        assertThat(lions.name()).isEqualTo("Lions");

        JsonNode assignmentJson = examples("core.team-player").getFirst();
        TeamPlayerChanged assignment = (TeamPlayerChanged) event("core.team-player", 0);
        assertThat(assignment.teamId()).isEqualTo(TeamId.of(UUID.fromString(assignmentJson.at("/payload/teamId").asText())));
        assertThat(assignment.playerId())
                .isEqualTo(PlayerId.of(UUID.fromString(assignmentJson.at("/payload/playerId").asText())));
        assertThat(assignment.jerseyNumber()).isEqualTo(text(assignmentJson, "/payload/jerseyNumber"));
        assertThat(assignment.joinedOn()).isEqualTo(LocalDate.parse(assignmentJson.at("/payload/joinedOn").asText()));
        assertThat(assignment.leftOn().map(LocalDate::toString)).isEqualTo(text(assignmentJson, "/payload/leftOn"));
        assertThat(assignment.invalidReason()).isEqualTo(text(assignmentJson, "/payload/invalidReason"));
    }

    @Test
    void staffEntriesAndGuardianLinksAreChangedOrRemoved() {
        TeamStaffChanged coach = (TeamStaffChanged) event("core.team-staff", 0);
        assertThat(coach.teamId()).isEqualTo(TeamId.of(UUID.fromString("3c4d5e6f-7081-4923-a4b5-c6d7e8f90a1b")));
        assertThat(coach.personId()).isEqualTo(UUID.fromString("9f0e1d2c-3b4a-4596-8877-665544332211"));
        assertThat(coach.role()).isEqualTo("COACH");
        TeamStaffRemoved detached = (TeamStaffRemoved) event("core.team-staff", 1);
        assertThat(detached.teamId()).isEqualTo(coach.teamId());
        assertThat(detached.personId()).isEqualTo(coach.personId());

        List<RosterEvent> links = new ArrayList<>();
        for (int i = 0; i < examples("core.guardian-link").size(); i++) {
            links.add(event("core.guardian-link", i));
        }
        assertThat(links).hasAtLeastOneElementOfType(GuardianLinkChanged.class)
                .hasAtLeastOneElementOfType(GuardianLinkRemoved.class);
        GuardianLinkChanged link = (GuardianLinkChanged) links.stream().filter(GuardianLinkChanged.class::isInstance)
                .findFirst().orElseThrow();
        JsonNode linkJson = examples("core.guardian-link").stream()
                .filter(e -> e.get("type").asText().equals("guardian-link.changed")).findFirst().orElseThrow();
        assertThat(link.guardianPersonId()).isEqualTo(UUID.fromString(linkJson.at("/payload/guardianPersonId").asText()));
        assertThat(link.playerId()).isEqualTo(PlayerId.of(UUID.fromString(linkJson.at("/payload/playerId").asText())));
    }

    @Test
    void tenantCarriesStatusAndZone() {
        TenantChanged suspended = (TenantChanged) event("core.tenant", 1);
        assertThat(suspended.status()).isEqualTo(TenantStatus.SUSPENDED);
        assertThat(suspended.timezone()).isEqualTo(ZoneId.of("Asia/Jakarta"));
    }

    @Test
    void aSchemaViolationIsRejectedWithTheEventIdAndTheReason() {
        ObjectNode broken = examples("core.team").getFirst().deepCopy();
        ((ObjectNode) broken.get("payload")).remove("name");

        Decoded.Invalid invalid = (Decoded.Invalid) decode("core.team", broken);

        assertThat(invalid.eventId()).contains(UUID.fromString("0190b6a1-0000-7000-8000-000000000021"));
        assertThat(invalid.reason()).contains("schema").contains("name");
    }

    @Test
    void anUnknownMemberIsASchemaViolation() {
        ObjectNode extra = examples("core.person").getFirst().deepCopy();
        ((ObjectNode) extra.get("payload")).put("email", "cora@example.org");

        assertThat(decode("core.person", extra)).isInstanceOf(Decoded.Invalid.class);
    }

    @Test
    void anEventOfAnotherTopicsContractIsRejected() {
        assertThat(decode("core.person", examples("core.team").getFirst())).isInstanceOf(Decoded.Invalid.class);
    }

    @Test
    void theKeyMustBeTheTenantAndTheAggregate() {
        JsonNode team = examples("core.team").getFirst();
        String value = team.toString();
        String aggregate = team.get("aggregateId").asText();

        assertThat(decoder.decode("core.team", aggregate, value)).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.reason()).contains("key"));
        assertThat(decoder.decode("core.team", TenantId.random() + ":" + aggregate, value))
                .isInstanceOf(Decoded.Invalid.class);
        assertThat(decoder.decode("core.team", null, value)).isInstanceOf(Decoded.Invalid.class);
        assertThat(decoder.decode("core.team", TENANT + ":" + aggregate, value)).isInstanceOf(Decoded.Valid.class);
    }

    @Test
    void aTenantEventMustBeAboutItsOwnTenant() {
        ObjectNode other = examples("core.tenant").getFirst().deepCopy();
        String otherTenant = UUID.randomUUID().toString();
        other.put("aggregateId", otherTenant);

        Decoded decoded = decoder.decode("core.tenant", TENANT + ":" + otherTenant, other.toString());

        assertThat(decoded).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.reason()).contains("tenant"));
    }

    @Test
    void anUnknownTimeZoneIsRejected() {
        ObjectNode tenant = examples("core.tenant").getFirst().deepCopy();
        ((ObjectNode) tenant.get("payload")).put("timezone", "Mars/Olympus_Mons");

        assertThat(decode("core.tenant", tenant)).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.reason()).contains("time zone"));
    }

    @Test
    void notJsonAndUnknownTopicsAreRejected() {
        assertThat(decoder.decode("core.team", TENANT + ":x", "{not json")).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.eventId()).isEmpty());
        assertThat(decoder.decode("core.team", TENANT + ":x", "[]")).isInstanceOf(Decoded.Invalid.class);
        assertThat(decoder.decode("core.season", TENANT + ":x", examples("core.team").getFirst().toString()))
                .isInstanceOfSatisfying(Decoded.Invalid.class, invalid -> assertThat(invalid.reason()).contains("topic"));
    }

    @Test
    void aLongReasonIsCutToTheParkedRecordsLimit() {
        String topic = "core." + "x".repeat(2_000);

        assertThat(decoder.decode(topic, TENANT + ":x", "{}")).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.reason()).hasSize(1_000).startsWith("unknown topic core.xxx"));
        assertThat(decoder.decode("core.unknown", TENANT + ":x", "{}")).isInstanceOfSatisfying(Decoded.Invalid.class,
                invalid -> assertThat(invalid.reason()).isEqualTo("unknown topic core.unknown"));
    }

    private RosterEvent event(String topic, int index) {
        Decoded decoded = decode(topic, examples(topic).get(index));
        assertThat(decoded).isInstanceOf(Decoded.Valid.class);
        return ((Decoded.Valid) decoded).event();
    }

    private Decoded decode(String topic, JsonNode event) {
        return decoder.decode(topic, event.get("tenantId").asText() + ":" + event.get("aggregateId").asText(),
                event.toString());
    }

    private static Optional<String> text(JsonNode node, String pointer) {
        JsonNode value = node.at(pointer);
        return value.isNull() || value.isMissingNode() ? Optional.empty() : Optional.of(value.asText());
    }

    static List<JsonNode> examples(String topic) {
        try (InputStream in = RosterEventDecoderTest.class.getResourceAsStream("/events/examples/" + topic + ".valid.json")) {
            List<JsonNode> examples = new ArrayList<>();
            JSON.readTree(in).forEach(examples::add);
            return examples;
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
