package com.hoopsacademy.athlete.domain;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.OptionalInt;

/**
 * Looks up the expected band of a result. Tenant rows replace the global rows of the same test and gender whose age
 * range they overlap; the player's gender and age at measurement select the rows, the value picks the band.
 * "Higher is better" does not take part in the lookup (the ranges say it all); it only orders a table for checks.
 */
public final class BandResolver {

    public enum Outcome {
        /** A norm row covers gender, age and value. */
        MATCHED,
        /** The player data is complete but no norm covers it (also: an override that leaves the value uncovered). */
        NO_NORM,
        /** Birth date or gender of the player is unknown, so no norm can be selected. */
        MISSING_PLAYER_DATA
    }

    public record Resolution(Outcome outcome, Optional<PhysicalTestNorm> norm) {

        public Optional<NormBand> expectedBand() {
            return norm.map(PhysicalTestNorm::band);
        }

        public boolean referencePending() {
            return norm.map(PhysicalTestNorm::referencePending).orElse(false);
        }
    }

    private BandResolver() {}

    /** @param norms every norm visible to the tenant for ONE test type (global and tenant rows) */
    public static Resolution resolve(Collection<PhysicalTestNorm> norms, Optional<Gender> gender, OptionalInt age,
            BigDecimal value) {
        if (gender.isEmpty() || age.isEmpty()) {
            return new Resolution(Outcome.MISSING_PLAYER_DATA, Optional.empty());
        }
        Optional<PhysicalTestNorm> match = effective(norms).stream()
                .filter(n -> n.covers(gender.get(), age.getAsInt()) && n.containsValue(value))
                .min(Comparator.comparing(PhysicalTestNorm::global).thenComparing(PhysicalTestNorm::band));
        return new Resolution(match.isPresent() ? Outcome.MATCHED : Outcome.NO_NORM, match);
    }

    /** Tenant rows plus the global rows that no tenant row of the same test and gender overlaps in age. */
    public static List<PhysicalTestNorm> effective(Collection<PhysicalTestNorm> norms) {
        List<PhysicalTestNorm> tenantRows = norms.stream().filter(n -> !n.global()).toList();
        List<PhysicalTestNorm> result = new ArrayList<>(tenantRows);
        norms.stream().filter(PhysicalTestNorm::global)
                .filter(g -> tenantRows.stream().noneMatch(t -> t.testTypeId().equals(g.testTypeId())
                        && t.gender() == g.gender() && t.overlapsAges(g)))
                .forEach(result::add);
        return result;
    }

    /**
     * Sanity check of the bands of one table (same test, gender and age): the lower bound of each band, taken from
     * POOR to EXCELLENT, never decreases when higher is better and never increases when lower is better.
     */
    public static boolean bandsAreOrdered(Collection<PhysicalTestNorm> bands, boolean higherIsBetter) {
        List<PhysicalTestNorm> sorted = bands.stream().sorted(Comparator.comparing(PhysicalTestNorm::band)).toList();
        BigDecimal previous = null;
        for (PhysicalTestNorm norm : sorted) {
            BigDecimal reference = higherIsBetter ? norm.minValue().orElse(null) : norm.maxValue().orElse(null);
            if (previous != null && reference != null) {
                int cmp = reference.compareTo(previous);
                if (higherIsBetter ? cmp < 0 : cmp > 0) {
                    return false;
                }
            }
            if (reference != null) {
                previous = reference;
            }
        }
        return true;
    }
}
