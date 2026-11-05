package com.hoopsacademy.core;

import com.hoopsacademy.common.testing.MutationTestScope;
import org.junit.jupiter.api.Test;

/** PIT runs only pure unit tests of this module (WP37, docs/quality/mutation.md); pit.targetTests lives in the pom. */
class MutationScopeTest {

    @Test
    void pitTargetTestsNamePureUnitTestsOnly() {
        MutationTestScope.checkTestCode("com.hoopsacademy.core", System.getProperty("pit.targetTests"));
    }
}
