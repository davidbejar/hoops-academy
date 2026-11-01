package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PhysicalTestType;
import com.hoopsacademy.athlete.domain.TestTypeId;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Test types visible to the current tenant: the global ones and its own. */
public interface TestTypeRepository {

    /** Inserts a tenant type or updates one of the tenant's types. */
    void save(PhysicalTestType type);

    Optional<PhysicalTestType> find(TestTypeId id);

    Map<TestTypeId, PhysicalTestType> findAll(Collection<TestTypeId> ids);

    /** Ordered by code. */
    List<PhysicalTestType> list();

    /** Does a visible type (global or the tenant's) already use the code? */
    boolean codeExists(String code);
}
