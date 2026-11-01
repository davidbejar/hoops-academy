package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "team_player")
public class TeamPlayerEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    @Column(name = "team_id")
    public UUID teamId;

    @Column(name = "player_id")
    public UUID playerId;

    @Column(name = "jersey_number")
    public String jerseyNumber;

    @Column(name = "joined_on")
    public LocalDate joinedOn;

    @Column(name = "left_on")
    public LocalDate leftOn;

    @Column(name = "play_up_levels")
    public int playUpLevels;

    @Column(name = "invalidated_at")
    public Instant invalidatedAt;

    @Column(name = "invalid_reason")
    public String invalidReason;
}
