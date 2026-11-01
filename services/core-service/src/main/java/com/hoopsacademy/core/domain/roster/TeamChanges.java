package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Patch;

/** A partial update of a team; only the alias may be cleared. */
public record TeamChanges(Patch<String> name, Patch<String> alias, Patch<AgeCategoryId> category,
        Patch<GenderPolicy> genderPolicy) {

    /** Category or gender policy changes require re-evaluating the team's players. */
    public boolean changesEligibility() {
        return category.isPresent() || genderPolicy.isPresent();
    }
}
