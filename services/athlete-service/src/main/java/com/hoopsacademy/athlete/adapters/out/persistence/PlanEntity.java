package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * Not annotated with {@code @TenantId}: Hibernate's discriminator filter would hide the global templates
 * (null owner). Visibility and write protection are the job of the RLS policies of the table.
 *
 * <p>{@code name_key} and {@code i18n} belong to the templates (seeded by R__plan_templates.sql, V4): read-only here,
 * so a tenant plan is always written without them.
 */
@Entity
@Table(name = "training_plan")
class PlanEntity {

    @Id
    UUID id;

    @Column(name = "owner_tenant_id", updatable = false)
    UUID ownerTenantId;

    @Column(name = "name_key", insertable = false, updatable = false)
    String nameKey;

    @Column(name = "name", nullable = false)
    String name;

    @Column(name = "description")
    String description;

    @Column(name = "author_person_id")
    UUID authorPersonId;

    @Column(name = "author_name")
    String authorName;

    @Column(name = "is_template", nullable = false, updatable = false)
    boolean template;

    @Column(name = "locale", nullable = false)
    String locale;

    /** jsonb {@code {"es": {"name": …, "description": …}, …}}, read as text. */
    @Column(name = "i18n", insertable = false, updatable = false)
    String i18n;

    @Column(name = "archived", nullable = false)
    boolean archived;

    @Column(name = "source_plan_id")
    UUID sourcePlanId;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    @Version
    @Column(name = "version", nullable = false)
    long version;
}
