package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * The eligibility rules of plan §2 for one tenant: the team's category must not be below the player's natural one,
 * a play-up is limited by {@code maxPlayUpLevels} (null = unlimited), the gender policy must admit the player, and
 * only ACTIVE/ORPHAN players with birth date and gender qualify. All failing rules are reported.
 */
public final class EligibilityEvaluator {

    private final CategoryLadder ladder;
    private final TenantSettings settings;
    private final AgeFunction ageFunction;

    public EligibilityEvaluator(CategoryLadder ladder, TenantSettings settings) {
        this.ladder = ladder;
        this.settings = settings;
        this.ageFunction = AgeFunction.of(settings.ageRule());
    }

    public Evaluation evaluate(EligibilityCandidate player, Team team, Season season, LocalDate asOf) {
        if (!team.season().equals(season.id())) {
            throw new IllegalArgumentException("The team does not belong to season " + season.id().value());
        }
        List<EligibilityReason> reasons = new ArrayList<>();
        if (!player.isActive()) {
            reasons.add(EligibilityReason.PLAYER_NOT_ACTIVE);
        }
        if (player.birthDate() == null) {
            reasons.add(EligibilityReason.MISSING_BIRTH_DATE);
        }
        if (player.gender() == null) {
            reasons.add(EligibilityReason.MISSING_GENDER);
        } else if (!team.genderPolicy().admits(player.gender())) {
            reasons.add(EligibilityReason.GENDER_POLICY);
        }
        if (player.birthDate() == null) {
            return new Evaluation(verdict(reasons, 0), null, null);
        }
        int age = ageFunction.ageOf(player.birthDate(), season.referenceYear(), asOf);
        Optional<AgeCategory> natural = ladder.naturalFor(age);
        int levels = natural.map(category -> ladder.levelsBetween(category, team.category())).orElse(-1);
        if (levels < 0) {
            reasons.add(EligibilityReason.CATEGORY_TOO_LOW);
        } else if (settings.maxPlayUpLevels() != null && levels > settings.maxPlayUpLevels()) {
            reasons.add(EligibilityReason.PLAY_UP_LIMIT_EXCEEDED);
        }
        return new Evaluation(verdict(reasons, levels), age, natural.orElse(null));
    }

    private static Eligibility verdict(List<EligibilityReason> reasons, int levels) {
        if (!reasons.isEmpty()) {
            return new Eligibility.Ineligible(reasons);
        }
        return levels == 0 ? new Eligibility.Eligible() : new Eligibility.PlayUp(levels);
    }
}
