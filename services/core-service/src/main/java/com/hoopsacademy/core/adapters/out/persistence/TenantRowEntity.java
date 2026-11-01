package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import org.hibernate.annotations.DynamicUpdate;

/**
 * The bound tenant's registry row as core_app sees it (RLS: own row only). Only profile columns are writable —
 * matching the column-level grant; slug and status are read-only here.
 */
@Entity
@Table(schema = "core", name = "tenant")
@DynamicUpdate
public class TenantRowEntity {

    @Id
    public UUID id;

    @Column(insertable = false, updatable = false)
    public String slug;

    public String name;

    @Column(insertable = false, updatable = false)
    public String status;

    public String timezone;

    @Column(name = "default_locale")
    public String defaultLocale;

    @Column(name = "contact_email")
    public String contactEmail;

    @Column(name = "website_url")
    public String websiteUrl;
}
