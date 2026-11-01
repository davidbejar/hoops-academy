package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** One row per tenant, keyed by the tenant id itself (RLS-protected; no discriminator field needed). */
@Entity
@Table(schema = "core", name = "tenant_settings")
public class TenantSettingsEntity {

    @Id
    @Column(name = "tenant_id")
    public UUID id;

    @Column(name = "age_rule")
    public String ageRule;

    @Column(name = "max_play_up_levels")
    public Integer maxPlayUpLevels;

    @Column(name = "attendance_late_threshold_minutes")
    public int attendanceLateThresholdMinutes;

    @Column(name = "updated_at")
    public Instant updatedAt;
}
