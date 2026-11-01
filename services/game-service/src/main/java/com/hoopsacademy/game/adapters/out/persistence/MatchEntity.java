package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.MatchStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "match")
class MatchEntity {

    @Id
    UUID id;

    @TenantId
    @Column(name = "tenant_id", updatable = false)
    String tenantId;

    @Column(name = "team_id", nullable = false, updatable = false)
    UUID teamId;

    @Column(name = "season_id", nullable = false, updatable = false)
    UUID seasonId;

    @Column(name = "opponent_name", nullable = false)
    String opponentName;

    @Enumerated(EnumType.STRING)
    @Column(name = "home_away", nullable = false)
    HomeAway homeAway;

    @Column(name = "scheduled_at", nullable = false)
    Instant scheduledAt;

    String venue;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    MatchStatus status;

    @Column(name = "period_count", nullable = false)
    int periodCount;

    @Column(name = "period_minutes", nullable = false)
    int periodMinutes;

    @Column(name = "started_at")
    Instant startedAt;

    @Column(name = "finished_at")
    Instant finishedAt;

    @Column(name = "cancelled_at")
    Instant cancelledAt;

    @Column(name = "cancel_reason")
    String cancelReason;

    @Column(name = "created_by_person_id", nullable = false, updatable = false)
    UUID createdByPersonId;

    @Version
    long version;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;
}
