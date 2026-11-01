package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import java.time.LocalDate;
import java.util.List;

/** The default ladder U8 … SENIOR and small builders shared by the eligibility tests. */
final class Fixtures {

    static final AgeCategory U8 = category("U8", 7, 0);
    static final AgeCategory U10 = category("U10", 9, 1);
    static final AgeCategory U12 = category("U12", 11, 2);
    static final AgeCategory U14 = category("U14", 13, 3);
    static final AgeCategory U16 = category("U16", 15, 4);
    static final AgeCategory U18 = category("U18", 17, 5);
    static final AgeCategory SENIOR = category("SENIOR", null, 6);
    static final List<AgeCategory> DEFAULTS = List.of(U8, U10, U12, U14, U16, U18, SENIOR);
    static final CategoryLadder LADDER = CategoryLadder.of(DEFAULTS);

    /** Season 2026/27, reference year 2026. */
    static final Season SEASON = new Season(SeasonId.random(), "2026/27", LocalDate.of(2026, 9, 1),
            LocalDate.of(2027, 6, 30), 2026);

    private Fixtures() {}

    static AgeCategory category(String code, Integer maxAge, int rank) {
        return new AgeCategory(AgeCategoryId.random(), code, code, maxAge, rank);
    }

    static Team team(AgeCategory category, GenderPolicy policy) {
        return new Team(TeamId.random(), SEASON.id(), category.code() + " " + policy, null, category.id(), policy);
    }

    static EligibilityCandidate player(LocalDate birthDate, Gender gender) {
        return new EligibilityCandidate(PlayerId.random(), PlayerStatus.ACTIVE, birthDate, gender);
    }
}
