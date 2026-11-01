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
@Table(schema = "core", name = "person")
public class PersonEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    @Column(name = "user_id")
    public UUID userId;

    @Column(name = "given_name")
    public String givenName;

    @Column(name = "family_name")
    public String familyName;

    public String email;
    public String phone;

    @Column(name = "birth_date")
    public LocalDate birthDate;

    public String gender;
    public String locale;
    public boolean active;

    @Column(name = "invitation_status")
    public String invitationStatus;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;

    @Column(name = "deactivated_at")
    public Instant deactivatedAt;
}
