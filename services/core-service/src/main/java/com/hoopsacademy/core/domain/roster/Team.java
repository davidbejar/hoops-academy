package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Require;
import java.util.Objects;

/** A squad within a season, with an age category and a gender policy. A blank alias is stored as none. */
public record Team(TeamId id, SeasonId season, String name, String alias, AgeCategoryId category,
        GenderPolicy genderPolicy) {

    public static final int MAX_NAME = 80;
    public static final int MAX_ALIAS = 40;

    public Team {
        Objects.requireNonNull(id, "id");
        Require.present(season, "seasonId");
        name = Require.text(name, "name", MAX_NAME);
        alias = alias == null || alias.isBlank() ? null : Require.text(alias, "alias", MAX_ALIAS);
        Require.present(category, "ageCategoryId");
        Require.present(genderPolicy, "genderPolicy");
    }

    public Team apply(TeamChanges changes) {
        return new Team(id, season, changes.name().applyTo(name), changes.alias().applyTo(alias),
                changes.category().applyTo(category), changes.genderPolicy().applyTo(genderPolicy));
    }

    /** The same team (name, alias, category, policy) in another season, with a new identity. */
    public Team cloneInto(SeasonId target) {
        return new Team(TeamId.random(), target, name, alias, category, genderPolicy);
    }
}
