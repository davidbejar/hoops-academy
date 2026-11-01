package com.hoopsacademy.archfixture.untaggedtenant.adapters.out.persistence;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "archfixture_untagged")
public class UntaggedEntity {
    @Id
    UUID id;

    String tenantId;
}
