package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "approval_request")
public class ApprovalRequestEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    public String action;

    @Column(name = "player_id")
    public UUID playerId;

    /** jsonb, read and written as text (the connection sends strings untyped, see stringtype=unspecified). */
    public String payload;

    @Column(name = "requested_by_person_id")
    public UUID requestedByPersonId;

    public String status;

    @Column(name = "decided_by_person_id")
    public UUID decidedByPersonId;

    @Column(name = "decided_at")
    public Instant decidedAt;

    @Column(name = "decision_note")
    public String decisionNote;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;

    @Version
    public long version;
}
