package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "team_staff")
@IdClass(TeamStaffEntity.Key.class)
public class TeamStaffEntity {

    /** Primary key (team_id, person_id). */
    public record Key(UUID teamId, UUID personId) implements Serializable {

        public Key() {
            this(null, null);
        }
    }

    @Id
    @Column(name = "team_id")
    public UUID teamId;

    @Id
    @Column(name = "person_id")
    public UUID personId;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    public String role;
    public LocalDate since;
}
