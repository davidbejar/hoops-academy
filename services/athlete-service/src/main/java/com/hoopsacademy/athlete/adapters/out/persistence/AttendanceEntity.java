package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "attendance")
@IdClass(AttendanceKey.class)
class AttendanceEntity {

    @Id
    @Column(name = "session_id")
    UUID sessionId;

    @Id
    @Column(name = "player_id")
    UUID playerId;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "status", nullable = false)
    String status;

    @Column(name = "minutes_late")
    Integer minutesLate;

    @Column(name = "note")
    String note;

    @Column(name = "recorded_by_person_id", nullable = false)
    UUID recordedByPersonId;

    @Column(name = "recorded_by_name", nullable = false)
    String recordedByName;

    @Column(name = "recorded_at", nullable = false)
    Instant recordedAt;
}
