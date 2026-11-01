package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "training_session")
class SessionEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "team_id", nullable = false)
    UUID teamId;

    @Column(name = "schedule_id")
    UUID scheduleId;

    @Column(name = "starts_at", nullable = false)
    Instant startsAt;

    @Column(name = "ends_at", nullable = false)
    Instant endsAt;

    @Column(name = "location")
    String location;

    @Column(name = "plan_id")
    UUID planId;

    @Column(name = "status", nullable = false)
    String status;

    @Column(name = "notes")
    String notes;

    @Column(name = "cancel_reason")
    String cancelReason;

    @Column(name = "manually_edited", nullable = false)
    boolean manuallyEdited;
}
