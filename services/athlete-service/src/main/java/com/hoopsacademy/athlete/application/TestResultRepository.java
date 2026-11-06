package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PhysicalTestResult;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TestResultId;
import com.hoopsacademy.athlete.domain.TestTypeId;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Optional;

public interface TestResultRepository {

    void save(PhysicalTestResult result);

    Optional<PhysicalTestResult> find(TestResultId id);

    void delete(TestResultId id);

    /** Newest first. {@code players} null = every player of the tenant. */
    PageResult<PhysicalTestResult> search(Collection<PlayerId> players, Optional<TestTypeId> type, LocalDate from,
            LocalDate to, int page, int size);

    long count();

    /** Does any result of the tenant use the test type? */
    boolean existsForType(TestTypeId type);
}
