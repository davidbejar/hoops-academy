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
@Table(name = "plan_completion")
@IdClass(CompletionKey.class)
class CompletionEntity {

    @Id
    @Column(name = "assignment_id")
    UUID assignmentId;

    @Id
    @Column(name = "player_id")
    UUID playerId;

    @Column(name = "id", nullable = false, updatable = false)
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    @Column(name = "status", nullable = false)
    String status;

    @Column(name = "note")
    String note;

    @Column(name = "marked_at", nullable = false)
    Instant markedAt;

    @Column(name = "marked_by_person_id", nullable = false)
    UUID markedByPersonId;

    @Column(name = "marked_by_name", nullable = false)
    String markedByName;
}
