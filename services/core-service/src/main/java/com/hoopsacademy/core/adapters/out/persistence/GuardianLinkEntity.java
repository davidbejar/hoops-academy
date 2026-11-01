package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "guardian_link")
public class GuardianLinkEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    @Column(name = "guardian_person_id")
    public UUID guardianPersonId;

    @Column(name = "player_id")
    public UUID playerId;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;
}
