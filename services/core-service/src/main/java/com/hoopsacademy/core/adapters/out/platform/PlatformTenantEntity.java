package com.hoopsacademy.core.adapters.out.platform;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** {@code core.tenant} as the platform role sees it (persistence unit "platform", all rows). */
@Entity
@Table(schema = "core", name = "tenant")
public class PlatformTenantEntity {

    @Id
    public UUID id;

    @Column(updatable = false)
    public String slug;

    public String name;
    public String status;

    @Column(name = "status_reason")
    public String statusReason;

    public String timezone;

    @Column(name = "default_locale")
    public String defaultLocale;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;

    @Column(name = "suspended_at")
    public Instant suspendedAt;

    @Column(name = "withdrawn_at")
    public Instant withdrawnAt;

    @Column(name = "retain_until")
    public LocalDate retainUntil;
}
