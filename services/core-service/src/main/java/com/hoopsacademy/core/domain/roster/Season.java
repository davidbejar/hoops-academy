package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Require;
import java.time.LocalDate;
import java.util.Objects;

/**
 * A dated period of a tenant (both days inclusive). {@code referenceYear} feeds the BIRTH_YEAR age rule (ADR-0010).
 * Seasons of a tenant never overlap (checked by the use case and by a database trigger, ADR-0014).
 */
public record Season(SeasonId id, String name, LocalDate startsOn, LocalDate endsOn, int referenceYear) {

    public static final int MAX_NAME = 60;
    public static final int MIN_REFERENCE_YEAR = 2000;
    public static final int MAX_REFERENCE_YEAR = 2100;

    public Season {
        Objects.requireNonNull(id, "id");
        name = Require.text(name, "name", MAX_NAME);
        Require.present(startsOn, "startsOn");
        Require.present(endsOn, "endsOn");
        if (endsOn.isBefore(startsOn)) {
            throw Require.violation("endsOn", "endsOn must not be before startsOn");
        }
        if (referenceYear < MIN_REFERENCE_YEAR || referenceYear > MAX_REFERENCE_YEAR) {
            throw Require.violation("referenceYear", "referenceYear must be 2000..2100");
        }
    }

    /** Shares at least one day with {@code other} (a season never overlaps itself). */
    public boolean overlaps(Season other) {
        return !other.id.equals(id) && !startsOn.isAfter(other.endsOn) && !other.startsOn.isAfter(endsOn);
    }

    public boolean isCurrent(LocalDate today) {
        return !today.isBefore(startsOn) && !today.isAfter(endsOn);
    }

    public boolean hasEnded(LocalDate today) {
        return today.isAfter(endsOn);
    }

    public Season apply(SeasonChanges changes) {
        return new Season(id, changes.name().applyTo(name), changes.startsOn().applyTo(startsOn),
                changes.endsOn().applyTo(endsOn), changes.referenceYear().applyTo(referenceYear));
    }
}
