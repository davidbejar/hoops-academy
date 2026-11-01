package com.hoopsacademy.common.fixturetests;

import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.Test;

class CommonLibraryArchitectureTest {

    @Test
    void libraryPackagesAreFreeOfCycles() {
        var classes = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages("com.hoopsacademy.common");

        slices().matching("com.hoopsacademy.common.(*)..").should().beFreeOfCycles().check(classes);
    }
}
