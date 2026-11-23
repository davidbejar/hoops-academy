package com.hoopsacademy.athlete.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/** The JPQL of a paged search: constant fragments joined with "and"; the page and the total share them. */
class PagedQueryTest {

    @Test
    void withoutConditionsEveryRowMatches() {
        PagedQuery<InjuryEntity> query = PagedQuery.over(null, InjuryEntity.class, "i");

        assertThat(query.selectJpql("i.id")).isEqualTo("select i from InjuryEntity i order by i.id");
        assertThat(query.countJpql()).isEqualTo("select count(i) from InjuryEntity i");
    }

    @Test
    void conditionsAreJoinedWithAndInBothQueries() {
        PagedQuery<InjuryEntity> query = PagedQuery.over(null, InjuryEntity.class, "i")
                .where("i.playerId in :players").bind("players", java.util.List.of())
                .where("i.status = :status").bind("status", "OPEN");

        assertThat(query.selectJpql("i.occurredOn desc, i.id")).isEqualTo("select i from InjuryEntity i "
                + "where i.playerId in :players and i.status = :status order by i.occurredOn desc, i.id");
        assertThat(query.countJpql())
                .isEqualTo("select count(i) from InjuryEntity i where i.playerId in :players and i.status = :status");
    }
}
