package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class IdentifiersTest {

    private static final UUID ID = UUID.fromString("11111111-2222-4333-8444-555555555555");

    @Test
    void identifiersPrintAsTheirUuid() {
        List<Object> ids = List.of(new AbsenceId(ID), new AssignmentId(ID), new BodyMeasurementId(ID), new InjuryId(ID),
                new NormId(ID), new PersonId(ID), new PlanId(ID), new PlanItemId(ID), new PlayerId(ID), new ScheduleId(ID),
                new SessionId(ID), new TestResultId(ID), new TestTypeId(ID));

        assertThat(ids).allSatisfy(id -> assertThat(id).hasToString(ID.toString()));
    }

    @Test
    void randomTestResultIdsAreFresh() {
        assertThat(TestResultId.random()).isNotNull().isNotEqualTo(TestResultId.random());
    }
}
