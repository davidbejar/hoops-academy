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
@Table(schema = "core", name = "season")
public class SeasonEntity {

    @Id
    public UUID id;

    @TenantId
    @Column(name = "tenant_id")
    public String tenantId;

    public String name;

    @Column(name = "start_date")
    public LocalDate startDate;

    @Column(name = "end_date")
    public LocalDate endDate;

    @Column(name = "reference_year")
    public int referenceYear;

    @Column(name = "created_at", updatable = false)
    public Instant createdAt;
}
