package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** The tenant logo bytes (ADR-0009), keyed by the tenant id. */
@Entity
@Table(schema = "core", name = "tenant_logo")
public class TenantLogoEntity {

    @Id
    @Column(name = "tenant_id")
    public UUID id;

    @Column(name = "content_type")
    public String contentType;

    public byte[] bytes;

    @Column(name = "size_bytes")
    public int sizeBytes;

    public String etag;

    @Column(name = "updated_at")
    public Instant updatedAt;
}
