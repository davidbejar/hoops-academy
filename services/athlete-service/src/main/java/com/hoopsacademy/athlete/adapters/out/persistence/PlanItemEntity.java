package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** See {@link PlanEntity}: no {@code @TenantId}, templates have a null owner. */
@Entity
@Table(name = "plan_item")
class PlanItemEntity {

    @Id
    UUID id;

    @Column(name = "plan_id", nullable = false, updatable = false)
    UUID planId;

    @Column(name = "owner_tenant_id", updatable = false)
    UUID ownerTenantId;

    @Column(name = "position", nullable = false)
    int position;

    @Column(name = "title", nullable = false)
    String title;

    @Column(name = "description")
    String description;

    @Column(name = "duration_min")
    Integer durationMinutes;

    @Column(name = "sets")
    Integer sets;

    @Column(name = "repetitions")
    Integer repetitions;

    @Column(name = "video_url")
    String videoUrl;

    /** Template items only (see {@link PlanEntity}): jsonb {@code {"es": {"title": …, "description": …}, …}}, read as text. */
    @Column(name = "i18n", insertable = false, updatable = false)
    String i18n;
}
