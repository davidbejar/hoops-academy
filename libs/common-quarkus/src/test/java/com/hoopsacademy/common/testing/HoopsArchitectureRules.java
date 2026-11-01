package com.hoopsacademy.common.testing;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

import com.tngtech.archunit.base.DescribedPredicate;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.domain.JavaMethodCall;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.CompositeArchRule;
import jakarta.persistence.Entity;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

/**
 * Architecture rules shared by all services (CLAUDE.md rule 4). Usage in a service test:
 * <pre>{@code
 * @Test void architecture() { HoopsArchitectureRules.checkProductionCode("com.hoopsacademy.core"); }
 * }</pre>
 */
public final class HoopsArchitectureRules {

    private static final String[] FRAMEWORK_PACKAGES = {
        "jakarta..", "javax..", "io.quarkus..", "org.hibernate..", "io.smallrye..", "io.vertx..",
        "com.fasterxml.jackson..", "org.eclipse.microprofile..", "org.jboss.."
    };
    private static final Set<String> NATIVE_SQL_METHODS = Set.of(
            "createNativeQuery", "createNativeMutationQuery", "createStatement", "prepareStatement", "prepareCall");
    private static final Set<String> NATIVE_SQL_OWNERS = Set.of(
            "jakarta.persistence.EntityManager", "org.hibernate.Session", "org.hibernate.SharedSessionContract",
            "org.hibernate.query.QueryProducer", "java.sql.Connection");

    private HoopsArchitectureRules() {}

    /** Imports the main (non-test) classes of {@code basePackage} and checks every rule. */
    public static void checkProductionCode(String basePackage) {
        JavaClasses classes = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages(basePackage);
        check(basePackage, classes);
    }

    public static void check(String basePackage, JavaClasses classes) {
        CompositeArchRule.of(all(basePackage)).check(classes);
    }

    public static List<ArchRule> all(String basePackage) {
        return List.of(
                hexagonalLayering(basePackage),
                domainIsFrameworkFree(basePackage),
                noTransactionsInRestAdapters(basePackage),
                nativeSqlOnlyInRepositories(basePackage),
                tenantIdFieldsAreHibernateTenantIds(basePackage));
    }

    public static ArchRule hexagonalLayering(String basePackage) {
        return layeredArchitecture().consideringOnlyDependenciesInLayers()
                .withOptionalLayers(true)
                .layer("Domain").definedBy(basePackage + ".domain..")
                .layer("Application").definedBy(basePackage + ".application..")
                .layer("Adapters").definedBy(basePackage + ".adapters..")
                .whereLayer("Adapters").mayNotBeAccessedByAnyLayer()
                .whereLayer("Application").mayOnlyBeAccessedByLayers("Adapters")
                .whereLayer("Domain").mayOnlyBeAccessedByLayers("Application", "Adapters")
                .as("domain <- application <- adapters (hexagonal layering)");
    }

    public static ArchRule domainIsFrameworkFree(String basePackage) {
        return noClasses().that().resideInAPackage(basePackage + ".domain..")
                .should().dependOnClassesThat().resideInAnyPackage(FRAMEWORK_PACKAGES)
                .allowEmptyShould(true)
                .as("domain classes must not depend on Jakarta/Quarkus/Hibernate/Jackson");
    }

    public static ArchRule noTransactionsInRestAdapters(String basePackage) {
        String rest = basePackage + ".adapters.in.rest..";
        return CompositeArchRule.of(noClasses().that().resideInAPackage(rest)
                        .should().beAnnotatedWith(Transactional.class).allowEmptyShould(true))
                .and(methods().that().areDeclaredInClassesThat().resideInAPackage(rest)
                        .should().notBeAnnotatedWith(Transactional.class).allowEmptyShould(true))
                .as("transactions start in application use cases, never in REST resources");
    }

    public static ArchRule nativeSqlOnlyInRepositories(String basePackage) {
        return noClasses().that().resideInAPackage(basePackage + "..")
                .and().haveSimpleNameNotEndingWith("Repository")
                .should().callMethodWhere(nativeSqlCall())
                .allowEmptyShould(true)
                .as("native SQL / JDBC statements only in *Repository classes");
    }

    public static ArchRule tenantIdFieldsAreHibernateTenantIds(String basePackage) {
        return fields().that().haveName("tenantId")
                .and().areDeclaredInClassesThat().resideInAPackage(basePackage + "..")
                .and().areDeclaredInClassesThat().areAnnotatedWith(Entity.class)
                .should().beAnnotatedWith(org.hibernate.annotations.TenantId.class)
                .allowEmptyShould(true)
                .as("entity tenantId fields carry @org.hibernate.annotations.TenantId");
    }

    private static DescribedPredicate<JavaMethodCall> nativeSqlCall() {
        return DescribedPredicate.describe("a native SQL / JDBC statement method",
                call -> NATIVE_SQL_METHODS.contains(call.getName()) && isNativeSqlApi(call.getTargetOwner()));
    }

    private static boolean isNativeSqlApi(JavaClass owner) {
        return Stream.concat(Stream.of(owner), owner.getAllRawInterfaces().stream())
                .map(JavaClass::getName)
                .anyMatch(NATIVE_SQL_OWNERS::contains);
    }
}
