package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "training_schedule")
class ScheduleEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "team_id", nullable = false)
    UUID teamId;

    @Column(name = "weekday", nullable = false)
    short weekday;

    @Column(name = "start_time", nullable = false)
    LocalTime startTime;

    @Column(name = "duration_min", nullable = false)
    int durationMin;

    @Column(name = "location")
    String location;

    @Column(name = "valid_from", nullable = false)
    LocalDate validFrom;

    @Column(name = "valid_to")
    LocalDate validTo;

    @Column(name = "active", nullable = false)
    boolean active;
}
