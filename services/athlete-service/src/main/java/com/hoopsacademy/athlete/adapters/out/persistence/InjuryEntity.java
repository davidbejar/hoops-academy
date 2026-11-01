package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "injury")
class InjuryEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "player_id", nullable = false)
    UUID playerId;

    @Column(name = "occurred_on", nullable = false)
    LocalDate occurredOn;

    @Column(name = "body_part", nullable = false)
    String bodyPart;

    @Column(name = "description")
    String description;

    @Column(name = "severity", nullable = false)
    String severity;

    @Column(name = "expected_return_on")
    LocalDate expectedReturnOn;

    @Column(name = "actual_return_on")
    LocalDate actualReturnOn;

    @Column(name = "status", nullable = false)
    String status;

    @Column(name = "reported_by_person_id", nullable = false, updatable = false)
    UUID reportedByPersonId;

    @Column(name = "reported_by_name", nullable = false, updatable = false)
    String reportedByName;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    @Version
    @Column(name = "version", nullable = false)
    long version;
}
