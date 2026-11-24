package com.hoopsacademy.common.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/** The JPQL of a paged list (core's CORE-03, athlete's ATH-10, one builder since WP137): constant fragments only. */
class PagedQueryTest {

    @Test
    void withoutConditionsEveryRowMatches() {
        PagedQuery query = PagedQuery.of(null, "from InjuryEntity i", "i").orderBy("i.id");

        assertThat(query.itemsJpql("select i")).isEqualTo("select i from InjuryEntity i order by i.id");
        assertThat(query.countJpql()).isEqualTo("select count(i) from InjuryEntity i");
    }

    @Test
    void conditionsAreJoinedWithAndInBothQueriesAndOnlyTheItemsAreOrdered() {
        PagedQuery query = PagedQuery.of(null, "from InjuryEntity i", "i")
                .where("i.playerId in :players", "players", List.of())
                .whereIf(Optional.of("OPEN"), "i.status = :status", "status", status -> status)
                .whereIf(Optional.empty(), "i.occurredOn <= :until", "until", until -> until)
                .orderBy("i.occurredOn desc, i.id");

        assertThat(query.itemsJpql("select i")).isEqualTo("select i from InjuryEntity i "
                + "where i.playerId in :players and i.status = :status order by i.occurredOn desc, i.id");
        assertThat(query.countJpql())
                .isEqualTo("select count(i) from InjuryEntity i where i.playerId in :players and i.status = :status");
    }
}
