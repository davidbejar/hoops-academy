package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class ActorTest {

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" ", "\t"})
    void anActorNeedsADisplayName(String displayName) {
        assertThatIllegalArgumentException().isThrownBy(() -> new Actor(PersonId.random(), displayName));
    }

    @Test
    void anActorKeepsItsDisplayName() {
        assertThat(new Actor(PersonId.random(), "Coach Carter").displayName()).isEqualTo("Coach Carter");
    }
}
