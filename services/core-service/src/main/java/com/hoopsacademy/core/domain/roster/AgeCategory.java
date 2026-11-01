package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Require;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * A tenant-configurable age band. {@code maxAge} is inclusive; {@code null} means no upper limit (senior).
 * {@code rank} orders the ladder: a higher rank is an older category.
 */
public record AgeCategory(AgeCategoryId id, String code, String name, Integer maxAge, int rank) {

    public static final int MIN_AGE = 3;
    public static final int MAX_AGE = 99;
    private static final Pattern CODE = Pattern.compile("^[A-Z0-9_]{1,16}$");
    private static final int MAX_NAME = 60;

    public AgeCategory {
        Objects.requireNonNull(id, "id");
        if (code == null || !CODE.matcher(code).matches()) {
            throw Require.violation("code", "code must match ^[A-Z0-9_]{1,16}$");
        }
        name = Require.text(name, "name", MAX_NAME);
        if (maxAge != null && (maxAge < MIN_AGE || maxAge > MAX_AGE)) {
            throw Require.violation("maxAge", "maxAge must be 3..99 or null");
        }
        if (rank < 0) {
            throw Require.violation("rank", "rank must be >= 0");
        }
    }

    public boolean isUnlimited() {
        return maxAge == null;
    }

    public boolean admitsAge(int age) {
        return maxAge == null || age <= maxAge;
    }

    public AgeCategory apply(AgeCategoryChanges changes) {
        return new AgeCategory(id, changes.code().applyTo(code), changes.name().applyTo(name),
                changes.maxAge().applyTo(maxAge), changes.rank().applyTo(rank));
    }
}
