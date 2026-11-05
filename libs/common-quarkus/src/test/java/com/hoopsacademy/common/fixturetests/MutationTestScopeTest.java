package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.MutationTestScope;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class MutationTestScopeTest {

    private static final String FIXTURES = "com.hoopsacademy.archfixture.mutationscope.";
    private static final JavaClasses CLASSES = new ClassFileImporter().importPackages(FIXTURES);

    @Test
    void globsThatMatchOnlyPureTestsPass() {
        assertThatCode(() -> MutationTestScope.check(FIXTURES + "Pure*", CLASSES)).doesNotThrowAnyException();
    }

    @ParameterizedTest
    @ValueSource(strings = {"ContainerBackedCheck", "ContainerBackedCheck$NestedCheck", "InheritsContainerCheck",
        "StartsContainerCheck"})
    void aMatchedContainerTestIsReportedByName(String containerTest) {
        assertThatThrownBy(() -> MutationTestScope.check(FIXTURES + "Pure*," + FIXTURES + containerTest, CLASSES))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining(FIXTURES + containerTest);
    }

    @Test
    void aWildcardReachesContainerTestsToo() {
        assertThatThrownBy(() -> MutationTestScope.check(FIXTURES + "*", CLASSES))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining("ContainerBackedCheck")
                .hasMessageContaining("StartsContainerCheck")
                .hasMessageNotContaining("PureRuleCheck");
    }

    @Test
    void aGlobThatMatchesNoTestIsReported() {
        assertThatThrownBy(() -> MutationTestScope.check(FIXTURES + "Pure*," + FIXTURES + "Typo*", CLASSES))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining(FIXTURES + "Typo*");
    }

    @Test
    void aGlobWithWhitespaceIsReportedBecausePitWouldNeverMatchIt() {
        assertThatThrownBy(() -> MutationTestScope.check(FIXTURES + "Pure*,\n  " + FIXTURES + "Pure*", CLASSES))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining("whitespace");
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"${pit.targetTests}"})
    void missingGlobsAreReported(String globs) {
        assertThatThrownBy(() -> MutationTestScope.check(globs, CLASSES))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining("pit.targetTests");
    }
}
