package com.hoopsacademy.athlete.architecture;

import com.hoopsacademy.common.testing.HoopsArchitectureRules;
import org.junit.jupiter.api.Test;

class AthleteArchitectureTest {

    @Test
    void productionCodeFollowsTheHexagonalRules() {
        HoopsArchitectureRules.checkProductionCode("com.hoopsacademy.athlete");
    }
}
