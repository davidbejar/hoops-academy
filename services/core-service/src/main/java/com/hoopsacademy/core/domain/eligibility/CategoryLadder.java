package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * A tenant's age categories ordered by rank. Invariant: ranks are distinct and {@code maxAge} strictly grows with
 * rank, with at most one unlimited (senior) category at the top — so the natural category is well defined.
 */
public final class CategoryLadder {

    public static final String ORDER_VIOLATION = "AGE_CATEGORY_ORDER";

    private final List<AgeCategory> ordered;

    private CategoryLadder(List<AgeCategory> ordered) {
        this.ordered = ordered;
    }

    public static CategoryLadder of(Collection<AgeCategory> categories) {
        List<AgeCategory> ordered = categories.stream().sorted(Comparator.comparingInt(AgeCategory::rank)).toList();
        for (int i = 1; i < ordered.size(); i++) {
            requireOrdered(ordered.get(i - 1), ordered.get(i));
        }
        return new CategoryLadder(ordered);
    }

    public List<AgeCategory> categories() {
        return ordered;
    }

    public Optional<AgeCategory> find(AgeCategoryId id) {
        return ordered.stream().filter(category -> category.id().equals(id)).findFirst();
    }

    /** The lowest-ranked category whose max age admits {@code age}; empty when the player is older than all. */
    public Optional<AgeCategory> naturalFor(int age) {
        return ordered.stream().filter(category -> category.admitsAge(age)).findFirst();
    }

    /** Ladder steps from {@code from} up to {@code to} (negative when {@code to} is lower). */
    public int levelsBetween(AgeCategory from, AgeCategoryId to) {
        return position(to) - position(from.id());
    }

    private int position(AgeCategoryId id) {
        for (int i = 0; i < ordered.size(); i++) {
            if (ordered.get(i).id().equals(id)) {
                return i;
            }
        }
        throw new IllegalArgumentException("Category " + id.value() + " is not on the ladder");
    }

    private static void requireOrdered(AgeCategory lower, AgeCategory higher) {
        boolean distinctRanks = lower.rank() != higher.rank();
        boolean ageGrows = !lower.isUnlimited() && (higher.isUnlimited() || higher.maxAge() > lower.maxAge());
        if (!distinctRanks || !ageGrows) {
            throw new DomainRuleViolation("Categories must have distinct ranks and a max age that grows with rank "
                    + "(only the top category may be unlimited): " + lower.code() + " vs " + higher.code(),
                    ORDER_VIOLATION);
        }
    }
}
