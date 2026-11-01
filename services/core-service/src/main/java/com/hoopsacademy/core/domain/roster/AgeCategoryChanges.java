package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Patch;

/** A partial update of an age category; {@code maxAge} may be cleared (= senior). */
public record AgeCategoryChanges(Patch<String> code, Patch<String> name, Patch<Integer> maxAge, Patch<Integer> rank) {

    /** Max age or rank change natural categories, so open assignments must be re-evaluated. */
    public boolean changesLadder() {
        return maxAge.isPresent() || rank.isPresent();
    }
}
