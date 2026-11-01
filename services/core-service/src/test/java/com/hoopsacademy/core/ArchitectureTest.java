package com.hoopsacademy.core;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.hoopsacademy.common.testing.HoopsArchitectureRules;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.Test;

class ArchitectureTest {

    private static final String BASE = "com.hoopsacademy.core";

    @Test
    void sharedHoopsRules() {
        HoopsArchitectureRules.checkProductionCode(BASE);
    }

    @Test
    void platformPersistenceIsOnlyUsedThroughApplicationPorts() {
        JavaClasses classes = new ClassFileImporter().withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages(BASE);
        noClasses().that().resideOutsideOfPackage(BASE + ".adapters.out.platform..")
                .should().dependOnClassesThat().resideInAPackage(BASE + ".adapters.out.platform..")
                .because("the core_platform datasource must stay behind TenantRepository & co.")
                .check(classes);
        noClasses().that().resideInAPackage(BASE + ".adapters.in..")
                .should().dependOnClassesThat().resideInAPackage(BASE + ".adapters.out..")
                .because("inbound adapters talk to use cases, never to persistence or clients")
                .check(classes);
    }
}
