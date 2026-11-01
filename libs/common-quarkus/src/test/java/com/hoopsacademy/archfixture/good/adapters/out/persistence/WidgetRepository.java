package com.hoopsacademy.archfixture.good.adapters.out.persistence;

import com.hoopsacademy.archfixture.good.application.WidgetPort;
import com.hoopsacademy.archfixture.good.domain.Widget;
import jakarta.persistence.EntityManager;

public class WidgetRepository implements WidgetPort {

    private final EntityManager entityManager;

    public WidgetRepository(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Override
    public void save(Widget widget) {
        entityManager.createNativeQuery("select 1").getSingleResult();
    }
}
