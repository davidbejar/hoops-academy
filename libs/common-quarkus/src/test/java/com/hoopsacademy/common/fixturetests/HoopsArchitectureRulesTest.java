package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.HoopsArchitectureRules;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class HoopsArchitectureRulesTest {

    private static final String FIXTURES = "com.hoopsacademy.archfixture.";

    private static JavaClasses importFixture(String name) {
        return new ClassFileImporter().importPackages(FIXTURES + name);
    }

    @Test
    void wellLayeredServicePassesAllRules() {
        assertThatCode(() -> HoopsArchitectureRules.check(FIXTURES + "good", importFixture("good")))
                .doesNotThrowAnyException();
    }

    @ParameterizedTest
    @CsvSource({
        "badlayering,     LeakyDomain",
        "frameworkdomain, AnnotatedDomain",
        "txresource,      TransactionalEndpoint",
        "nativesql,       SneakyUseCase",
        "nativesql,       JdbcHelper",
        "untaggedtenant,  UntaggedEntity"
    })
    void eachViolationIsReported(String fixture, String offendingClass) {
        assertThatThrownBy(() -> HoopsArchitectureRules.check(FIXTURES + fixture, importFixture(fixture)))
                .isInstanceOf(AssertionError.class)
                .hasMessageContaining(offendingClass);
    }

    @Test
    void offersOneNamedRulePerConcern() {
        assertThat(HoopsArchitectureRules.all(FIXTURES + "good")).hasSize(5);
    }

    @Test
    void checkingProductionCodeOfAPackageSkipsTestClasses() {
        // the fixture violates the rules, but it is test code and therefore not imported
        assertThatCode(() -> HoopsArchitectureRules.checkProductionCode(FIXTURES + "nativesql"))
                .doesNotThrowAnyException();
    }
}
