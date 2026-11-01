package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "team")
public class TeamEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    @Column(name = "season_id")
    public UUID seasonId;

    public String name;
    public String alias;

    @Column(name = "age_category_id")
    public UUID ageCategoryId;

    @Column(name = "gender_policy")
    public String genderPolicy;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;
}
