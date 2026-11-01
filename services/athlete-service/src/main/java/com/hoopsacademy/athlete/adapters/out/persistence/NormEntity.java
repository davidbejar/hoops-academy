package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Not annotated with {@code @TenantId} for the same reason as {@link TestTypeEntity}: global rows have no owner. */
@Entity
@Table(name = "physical_test_norm")
class NormEntity {

    @Id
    UUID id;

    @Column(name = "owner_tenant_id", updatable = false)
    UUID ownerTenantId;

    @Column(name = "test_type_id", nullable = false)
    UUID testTypeId;

    @Column(name = "gender", nullable = false)
    String gender;

    @Column(name = "min_age", nullable = false)
    int minAge;

    @Column(name = "max_age", nullable = false)
    int maxAge;

    @Column(name = "band", nullable = false)
    String band;

    @Column(name = "min_value")
    BigDecimal minValue;

    @Column(name = "max_value")
    BigDecimal maxValue;

    @Column(name = "reference_pending", nullable = false)
    boolean referencePending;

    @Column(name = "source")
    String source;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;
}
