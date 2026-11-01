package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "eligibility_case")
public class EligibilityCaseEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    @Column(name = "player_id")
    public UUID playerId;

    @Column(name = "team_player_id")
    public UUID teamPlayerId;

    public String reason;
    public String status;
    public String resolution;

    @Column(name = "resolution_note")
    public String resolutionNote;

    @Column(name = "resolved_by_person_id")
    public UUID resolvedByPersonId;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;

    @Column(name = "resolved_at")
    public Instant resolvedAt;
}
