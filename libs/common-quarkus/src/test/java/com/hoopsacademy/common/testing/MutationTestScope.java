package com.hoopsacademy.common.testing;

import com.tngtech.archunit.core.domain.Dependency;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Keeps PIT's test selection pure (WP37, docs/quality/mutation.md). A module's {@code pit.targetTests} globs name the
 * unit tests PIT runs once per mutant; a container test among them would boot Quarkus or Postgres thousands of times.
 * This check fails the default build when a matched test class (or its enclosing class or a superclass) is a Quarkus
 * test or touches Testcontainers, when a glob matches no test (a typo silently shrinks the run) and when a glob carries
 * whitespace (PIT does not trim, so it would never match).
 */
public final class MutationTestScope {

    /** Packages a pure unit test never depends on: Quarkus test annotations and resources, Testcontainers. */
    private static final List<String> CONTAINER_PACKAGES = List.of("io.quarkus.test.", "org.testcontainers.");

    private MutationTestScope() {}

    /** Checks the globs (as passed by surefire from the module's {@code pit.targetTests}) against its test classes. */
    public static void checkTestCode(String basePackage, String globs) {
        JavaClasses testClasses = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.ONLY_INCLUDE_TESTS)
                .importPackages(basePackage);
        check(globs, testClasses);
    }

    public static void check(String globs, JavaClasses testClasses) {
        List<String> patterns = parse(globs);
        Set<String> problems = new LinkedHashSet<>();
        for (String glob : patterns) {
            Pattern pattern = toRegex(glob);
            List<JavaClass> matched = testClasses.stream().filter(c -> pattern.matcher(c.getName()).matches()).toList();
            if (matched.isEmpty()) {
                problems.add("glob " + glob + " matches no test class");
            }
            matched.stream().filter(MutationTestScope::needsContainers)
                    .forEach(c -> problems.add(c.getName() + " needs containers but matches glob " + glob));
        }
        if (!problems.isEmpty()) {
            throw new AssertionError("pit.targetTests must name pure unit tests only:\n  "
                    + String.join("\n  ", problems));
        }
    }

    private static List<String> parse(String globs) {
        if (globs == null || globs.isBlank() || globs.contains("${")) {
            throw new AssertionError("pit.targetTests is not set: surefire must pass the module property through");
        }
        List<String> patterns = Arrays.asList(globs.split(","));
        List<String> padded = patterns.stream().filter(g -> !g.equals(g.strip()) || g.isEmpty()).toList();
        if (!padded.isEmpty()) {
            throw new AssertionError("pit.targetTests globs must not carry whitespace (PIT never matches them): "
                    + padded);
        }
        return patterns;
    }

    /** PIT's glob: {@code *} is any sequence of characters (dots and {@code $} included); everything else is literal. */
    private static Pattern toRegex(String glob) {
        return Pattern.compile(Arrays.stream(glob.split("\\*", -1)).map(Pattern::quote).collect(Collectors.joining(".*")));
    }

    private static boolean needsContainers(JavaClass testClass) {
        return selfEnclosingAndSuperclasses(testClass).anyMatch(MutationTestScope::dependsOnContainers);
    }

    private static Stream<JavaClass> selfEnclosingAndSuperclasses(JavaClass testClass) {
        Stream<JavaClass> enclosing = Stream.iterate(testClass.getEnclosingClass(), Optional::isPresent,
                c -> c.get().getEnclosingClass()).map(Optional::get);
        return Stream.concat(Stream.concat(Stream.of(testClass), enclosing), testClass.getAllRawSuperclasses().stream());
    }

    private static boolean dependsOnContainers(JavaClass javaClass) {
        return javaClass.getDirectDependenciesFromSelf().stream()
                .map(Dependency::getTargetClass)
                .anyMatch(target -> CONTAINER_PACKAGES.stream().anyMatch(target.getName()::startsWith));
    }
}
