package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(schema = "core", name = "membership_role")
@IdClass(MembershipRoleEntity.Key.class)
public class MembershipRoleEntity {

    /** Composite key (person_id, role). */
    public record Key(UUID personId, String role) implements Serializable {

        public Key() {
            this(null, null);
        }
    }

    @Id
    @Column(name = "person_id")
    public UUID personId;

    @Id
    public String role;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    public MembershipRoleEntity() {}

    MembershipRoleEntity(UUID personId, String role) {
        this.personId = personId;
        this.role = role;
    }
}
