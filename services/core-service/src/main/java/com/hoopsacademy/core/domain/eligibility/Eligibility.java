package com.hoopsacademy.core.domain.eligibility;

import java.util.List;

/** Verdict for one player and one team: ELIGIBLE, PLAY_UP(n) or INELIGIBLE(reasons). */
public sealed interface Eligibility {

    /** The team's category is the player's natural one. */
    record Eligible() implements Eligibility {}

    /** The team plays {@code levels} ≥ 1 categories above the player's natural one, within the tenant limit. */
    record PlayUp(int levels) implements Eligibility {

        public PlayUp {
            if (levels < 1) {
                throw new IllegalArgumentException("A play-up is at least one level");
            }
        }
    }

    /** The player may not be on the team; {@code reasons} is never empty. */
    record Ineligible(List<EligibilityReason> reasons) implements Eligibility {

        public Ineligible {
            if (reasons.isEmpty()) {
                throw new IllegalArgumentException("An ineligible verdict needs a reason");
            }
            reasons = List.copyOf(reasons);
        }

        public EligibilityReason primaryReason() {
            return reasons.get(0);
        }
    }

    default boolean allowed() {
        return !(this instanceof Ineligible);
    }

    default int playUpLevels() {
        return this instanceof PlayUp playUp ? playUp.levels() : 0;
    }

    default List<EligibilityReason> reasons() {
        return this instanceof Ineligible ineligible ? ineligible.reasons() : List.of();
    }
}
