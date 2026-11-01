package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.util.Objects;
import java.util.regex.Pattern;

/** A kind of physical test: platform-provided (global, read-only) or defined by a tenant. */
public record PhysicalTestType(TestTypeId id, String code, String name, String unit, boolean higherIsBetter,
        String description, boolean global) {

    private static final Pattern CODE = Pattern.compile("[A-Z0-9_]{2,32}");

    public PhysicalTestType {
        Objects.requireNonNull(id, "id");
        if (code == null || !CODE.matcher(code).matches() || isBlank(name) || name.length() > 120 || isBlank(unit)
                || unit.length() > 16 || (description != null && description.length() > 2000)) {
            throw new DomainRuleViolation("A test type needs a code (A-Z, 0-9, _; 2-32), a name and a unit", "INVALID_TEST_TYPE");
        }
    }

    public static PhysicalTestType custom(String code, String name, String unit, boolean higherIsBetter, String description) {
        return new PhysicalTestType(TestTypeId.random(), code, name, unit, higherIsBetter, description, false);
    }

    /** @throws AccessDeniedException {@code TEST_TYPE_IS_GLOBAL} for a platform type */
    public PhysicalTestType changedTo(String newName, String newUnit, boolean newHigherIsBetter, String newDescription) {
        if (global) {
            throw new AccessDeniedException("Global test types are read-only", "TEST_TYPE_IS_GLOBAL");
        }
        return new PhysicalTestType(id, code, newName, newUnit, newHigherIsBetter, newDescription, false);
    }

    private static boolean isBlank(String text) {
        return text == null || text.isBlank();
    }
}
