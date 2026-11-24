package com.hoopsacademy.common.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import jakarta.persistence.Query;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/** CORE-03: the optional filters of a paged list, written once and bound alike to its items and count queries. */
class QueryConditionsTest {

    @Test
    void noConditionIsNoWhereClause() {
        assertThat(new QueryConditions().where()).isEmpty();
    }

    @Test
    void conditionsAreJoinedWithAndInTheOrderTheyWereAdded() {
        QueryConditions conditions = new QueryConditions().add("pe.id = p.personId")
                .add("p.status = :status", "status", "ACTIVE");

        assertThat(conditions.where()).isEqualTo(" where pe.id = p.personId and p.status = :status");
    }

    @Test
    void anAbsentFilterAddsNeitherAConditionNorAParameter() {
        Query query = mock(Query.class);
        QueryConditions conditions = new QueryConditions()
                .addIf(Optional.<Integer>empty(), "t.rank = :rank", "rank", rank -> rank);

        conditions.bind(query);

        assertThat(conditions.where()).isEmpty();
        verifyNoInteractions(query);
    }

    @Test
    void aPresentFilterAddsItsConditionAndBindsItsConvertedValue() {
        Query query = mock(Query.class);
        QueryConditions conditions = new QueryConditions()
                .addIf(Optional.of(3), "t.rank = :rank", "rank", rank -> rank * 10);

        conditions.bind(query);

        assertThat(conditions.where()).isEqualTo(" where t.rank = :rank");
        verify(query).setParameter("rank", 30);
    }
}
