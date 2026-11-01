package com.hoopsacademy.common.sample;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

/**
 * Test entity for {@code core.sample_widget}. The tenant column is {@code uuid} in the database but a String here:
 * Quarkus hands Hibernate the tenant id as a String (see ADR-0011).
 */
@Entity
@Table(schema = "core", name = "sample_widget")
public class SampleWidget {

    @Id
    @GeneratedValue
    UUID id;

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    String tenantId;

    String name;

    @Column(name = "size_cm")
    int sizeCm;

    protected SampleWidget() {}

    public SampleWidget(String name, int sizeCm) {
        this.name = name;
        this.sizeCm = sizeCm;
    }

    public UUID id() {
        return id;
    }

    public String tenantId() {
        return tenantId;
    }
}
