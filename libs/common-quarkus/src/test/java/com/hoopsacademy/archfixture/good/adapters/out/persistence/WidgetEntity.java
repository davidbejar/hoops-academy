package com.hoopsacademy.archfixture.good.adapters.out.persistence;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import org.hibernate.annotations.TenantId;

@Entity
@Table(name = "archfixture_good_widget")
public class WidgetEntity {
    @Id
    UUID id;

    @TenantId
    String tenantId;
}
