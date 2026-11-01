package com.hoopsacademy.game.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "match_roster")
@IdClass(MatchRosterEntity.Key.class)
class MatchRosterEntity {

    record Key(UUID matchId, UUID playerId) implements Serializable {}

    @Id
    @Column(name = "match_id")
    UUID matchId;

    @Id
    @Column(name = "player_id")
    UUID playerId;

    @TenantId
    @Column(name = "tenant_id", updatable = false)
    String tenantId;

    @Column(name = "display_name", nullable = false)
    String displayName;

    @Column(name = "jersey_number")
    String jerseyNumber;

    @Column(name = "is_starter", nullable = false)
    boolean starter;
}
