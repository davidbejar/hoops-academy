package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.eligibility.CategoryLadder;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryChanges;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.ArrayList;
import java.util.List;

/** The tenant's category ladder: any member reads, ADMIN edits; the ladder stays ordered (422) and unique (409). */
@ApplicationScoped
public class AgeCategoryService {

    public static final String CODE_TAKEN = "AGE_CATEGORY_CODE_TAKEN";
    public static final String RANK_TAKEN = "AGE_CATEGORY_RANK_TAKEN";
    public static final String IN_USE = "AGE_CATEGORY_IN_USE";

    /** Contract {@code AgeCategoryInput}. */
    public record NewAgeCategory(String code, String name, Integer maxAge, int rank) {}

    private final AgeCategoryRepository categories;
    private final TeamRepository teams;
    private final EligibilityEngine engine;

    public AgeCategoryService(AgeCategoryRepository categories, TeamRepository teams, EligibilityEngine engine) {
        this.categories = categories;
        this.teams = teams;
        this.engine = engine;
    }

    @Transactional
    public List<AgeCategory> list() {
        return categories.listByRank();
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public AgeCategory create(NewAgeCategory input) {
        AgeCategory category = new AgeCategory(AgeCategoryId.random(), input.code(), input.name(), input.maxAge(),
                input.rank());
        requireFitsLadder(category, categories.listByRank());
        categories.insert(category);
        return category;
    }

    /** Changing max age or rank re-evaluates every open assignment of current and upcoming seasons. */
    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public AgeCategory update(AgeCategoryId id, AgeCategoryChanges changes) {
        AgeCategory before = find(id);
        AgeCategory after = before.apply(changes);
        List<AgeCategory> others = categories.listByRank().stream().filter(c -> !c.id().equals(id)).toList();
        requireFitsLadder(after, others);
        if (after.equals(before)) {
            return before;
        }
        categories.update(after);
        if (changes.changesLadder()) {
            engine.reevaluateTenant();
        }
        return after;
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public void delete(AgeCategoryId id) {
        find(id);
        if (teams.usesCategory(id)) {
            throw new ConflictException("The age category is used by a team", IN_USE);
        }
        categories.delete(id);
    }

    private AgeCategory find(AgeCategoryId id) {
        return categories.find(id).orElseThrow(() -> new NotFoundException("Age category not found"));
    }

    private static void requireFitsLadder(AgeCategory candidate, List<AgeCategory> others) {
        if (others.stream().anyMatch(c -> c.code().equals(candidate.code()))) {
            throw new ConflictException("An age category with this code exists", CODE_TAKEN);
        }
        if (others.stream().anyMatch(c -> c.rank() == candidate.rank())) {
            throw new ConflictException("An age category with this rank exists", RANK_TAKEN);
        }
        List<AgeCategory> ladder = new ArrayList<>(others);
        ladder.add(candidate);
        CategoryLadder.of(ladder);
    }
}
