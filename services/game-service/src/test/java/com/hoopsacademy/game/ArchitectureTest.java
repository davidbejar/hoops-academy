package com.hoopsacademy.game;

import com.hoopsacademy.common.testing.HoopsArchitectureRules;
import org.junit.jupiter.api.Test;

class ArchitectureTest {

    @Test
    void productionCodeFollowsTheHexagonalRules() {
        HoopsArchitectureRules.checkProductionCode("com.hoopsacademy.game");
    }
}
