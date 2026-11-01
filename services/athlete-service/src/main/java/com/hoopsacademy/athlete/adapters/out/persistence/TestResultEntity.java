package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "physical_test_result")
class TestResultEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "player_id", nullable = false)
    UUID playerId;

    @Column(name = "test_type_id", nullable = false)
    UUID testTypeId;

    @Column(name = "measured_on", nullable = false)
    LocalDate measuredOn;

    @Column(name = "value", nullable = false)
    BigDecimal value;

    @Column(name = "notes")
    String notes;

    @Column(name = "recorded_by_person_id", nullable = false, updatable = false)
    UUID recordedByPersonId;

    @Column(name = "recorded_by_name", nullable = false, updatable = false)
    String recordedByName;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;
}
