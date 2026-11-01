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
@Table(name = "plan_assignment")
class AssignmentEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "plan_id", nullable = false, updatable = false)
    UUID planId;

    @Column(name = "team_id", updatable = false)
    UUID teamId;

    @Column(name = "player_id", updatable = false)
    UUID playerId;

    @Column(name = "due_on", nullable = false)
    LocalDate dueOn;

    @Column(name = "notes")
    String notes;

    @Column(name = "assigned_by_person_id", nullable = false)
    UUID assignedByPersonId;

    @Column(name = "assigned_by_name", nullable = false)
    String assignedByName;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;
}
