package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "planned_absence")
class AbsenceEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "player_id", nullable = false)
    UUID playerId;

    @Column(name = "from_date", nullable = false)
    LocalDate fromDate;

    @Column(name = "to_date", nullable = false)
    LocalDate toDate;

    @Column(name = "reason")
    String reason;

    @Column(name = "created_by_person_id", nullable = false)
    UUID createdByPersonId;

    @Column(name = "created_by_name", nullable = false)
    String createdByName;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;
}
