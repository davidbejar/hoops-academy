package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Not annotated with {@code @TenantId}: Hibernate's discriminator filter would hide the global types (null owner).
 * Visibility and write protection are the job of the RLS policies of the table.
 */
@Entity
@Table(name = "physical_test_type")
class TestTypeEntity {

    @Id
    UUID id;

    @Column(name = "owner_tenant_id", updatable = false)
    UUID ownerTenantId;

    @Column(name = "code", nullable = false)
    String code;

    @Column(name = "name", nullable = false)
    String name;

    @Column(name = "unit", nullable = false)
    String unit;

    @Column(name = "higher_is_better", nullable = false)
    boolean higherIsBetter;

    @Column(name = "description")
    String description;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;
}
