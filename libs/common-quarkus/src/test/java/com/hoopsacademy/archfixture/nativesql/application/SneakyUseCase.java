package com.hoopsacademy.archfixture.nativesql.application;

import jakarta.persistence.EntityManager;

public class SneakyUseCase {

    private final EntityManager entityManager;

    public SneakyUseCase(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public Object run() {
        return entityManager.createNativeQuery("delete from core.sample_widget").executeUpdate();
    }
}
