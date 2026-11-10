package com.hoopsacademy.athlete.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * Not annotated with {@code @TenantId}: Hibernate's discriminator filter would hide the global exercises (null owner).
 * Visibility and write protection are the job of the RLS policies of the table (V10).
 *
 * <p>{@code name_key} and {@code i18n} belong to the global exercises (seeded by R__exercise_catalogue.sql): read-only
 * here, so an academy's exercise is always written without them.
 */
@Entity
@Table(name = "exercise")
class ExerciseEntity {

    @Id
    UUID id;

    @Column(name = "owner_tenant_id", updatable = false)
    UUID ownerTenantId;

    @Column(name = "name_key", insertable = false, updatable = false)
    String nameKey;

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

    @Column(name = "locale", nullable = false)
    String locale;

    /** jsonb {@code {"es": {"title": …, "description": …}, …}}, read as text. */
    @Column(name = "i18n", insertable = false, updatable = false)
    String i18n;

    @Column(name = "archived", nullable = false)
    boolean archived;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    @Version
    @Column(name = "version", nullable = false)
    long version;
}
