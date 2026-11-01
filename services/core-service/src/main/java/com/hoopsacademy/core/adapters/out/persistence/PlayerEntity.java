package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "player")
public class PlayerEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    @Column(name = "person_id")
    public UUID personId;

    public String status;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;
}
