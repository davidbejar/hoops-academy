package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** Global login row (no tenant). */
@Entity
@Table(schema = "core", name = "app_user")
public class AppUserEntity {

    @Id
    public UUID id;

    @Column(name = "keycloak_sub", updatable = false)
    public String keycloakSub;

    public String email;

    public String locale;
}
