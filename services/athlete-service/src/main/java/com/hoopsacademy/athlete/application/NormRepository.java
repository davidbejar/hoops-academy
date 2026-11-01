package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.NormId;
import com.hoopsacademy.athlete.domain.PhysicalTestNorm;
import com.hoopsacademy.athlete.domain.TestTypeId;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** Norms visible to the current tenant: the global reference rows and its own overrides. */
public interface NormRepository {

    /** Inserts a tenant norm or updates one of the tenant's norms. */
    void save(PhysicalTestNorm norm);

    Optional<PhysicalTestNorm> find(NormId id);

    void delete(NormId id);

    /** Ordered by test type, gender, age and band. */
    List<PhysicalTestNorm> list(Optional<TestTypeId> type, Optional<Gender> gender);

    List<PhysicalTestNorm> forTypes(Collection<TestTypeId> types);

    /** The tenant's own norms of a test type and gender. */
    List<PhysicalTestNorm> tenantNorms(TestTypeId type, Gender gender);
}
