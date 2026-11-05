package com.hoopsacademy.core.domain.membership;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class GuardianLinkIdTest {

    @Test
    void randomIdsAreFreshEachTime() {
        GuardianLinkId first = GuardianLinkId.random();

        assertThat(first).isNotNull().isNotEqualTo(GuardianLinkId.random());
    }
}
