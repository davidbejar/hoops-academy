package com.hoopsacademy.common.problem;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class SeasonEndedExceptionTest {

    @Test
    void isAConflictWithTheSeasonEndedCode() {
        SeasonEndedException ended = new SeasonEndedException("The season of team T has ended");

        assertThat(ended).isInstanceOf(ConflictException.class);
        assertThat(ended.code()).isEqualTo(SeasonEndedException.CODE).isEqualTo("SEASON_ENDED");
        assertThat(ended.getMessage()).isEqualTo("The season of team T has ended");
    }
}
