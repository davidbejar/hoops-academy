package com.hoopsacademy.core.application.events;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class EventTopicTest {

    @Test
    void theTopicsAreTheSevenOfTheBrokerAndTheirTypesFollowTheAggregate() {
        assertThat(Arrays.stream(EventTopic.values()).map(EventTopic::topic)).containsExactly("core.person",
                "core.player", "core.team", "core.team-player", "core.team-staff", "core.guardian-link", "core.tenant");
        assertThat(EventTopic.TEAM_PLAYER.aggregate()).isEqualTo("team-player");
        assertThat(EventTopic.TEAM_PLAYER.changedType()).isEqualTo("team-player.changed");
        assertThat(EventTopic.GUARDIAN_LINK.removedType()).isEqualTo("guardian-link.removed");
        assertThat(EventTopic.VERSION).isEqualTo(1);
    }

    @Test
    void onlyTeamStaffAndGuardianLinksHaveRemovedEvents() {
        assertThat(EventTopic.TEAM_STAFF.isRemovedType("team-staff.removed")).isTrue();
        assertThat(EventTopic.TEAM_STAFF.isRemovedType("team-staff.changed")).isFalse();
        assertThat(EventTopic.PERSON.isRemovedType("person.removed")).isFalse();
        assertThatThrownBy(EventTopic.PERSON::removedType).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("core.person");
    }

    @Test
    void aTopicIsFoundByItsName() {
        assertThat(EventTopic.ofTopic("core.guardian-link")).isEqualTo(EventTopic.GUARDIAN_LINK);
        assertThatThrownBy(() -> EventTopic.ofTopic("core.season")).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void theTeamStaffIdIsTheContractsNameBasedUuid() {
        UUID team = UUID.fromString("3c4d5e6f-7081-4923-a4b5-c6d7e8f90a1b");
        UUID person = UUID.fromString("9f0e1d2c-3b4a-4596-8877-665544332211");

        UUID id = EventTopic.teamStaffId(team, person);

        assertThat(id).isEqualTo(UUID.nameUUIDFromBytes(("team-staff:" + team + ":" + person)
                .getBytes(StandardCharsets.UTF_8)));
        assertThat(id.version()).isEqualTo(3);
        assertThat(EventTopic.teamStaffId(person, team)).isNotEqualTo(id);
    }
}
