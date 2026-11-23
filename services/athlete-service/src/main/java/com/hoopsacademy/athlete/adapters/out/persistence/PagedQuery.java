package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.common.paging.PageOffset;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * A paged JPQL search over one entity with optional filters (ATH-10): each filter is a constant fragment whose values
 * are bound parameters, never query text; {@link #page} runs the page and the total with the same filters.
 */
final class PagedQuery<E> {

    private final EntityManager em;
    private final Class<E> entity;
    private final String alias;
    private final List<String> conditions = new ArrayList<>();
    private final Map<String, Object> parameters = new LinkedHashMap<>();

    private PagedQuery(EntityManager em, Class<E> entity, String alias) {
        this.em = em;
        this.entity = entity;
        this.alias = alias;
    }

    /** A search over {@code entity}, named {@code alias} in the fragments. */
    static <E> PagedQuery<E> over(EntityManager em, Class<E> entity, String alias) {
        return new PagedQuery<>(em, entity, alias);
    }

    /** Adds a constant condition; all conditions must hold. */
    PagedQuery<E> where(String condition) {
        conditions.add(condition);
        return this;
    }

    /** Binds a parameter the conditions name. */
    PagedQuery<E> bind(String name, Object value) {
        parameters.put(name, value);
        return this;
    }

    /** Page {@code page} of {@code size} rows in {@code orderBy} order, mapped, with the total of all matching rows. */
    <D> PageResult<D> page(String orderBy, int page, int size, Function<E, D> toDomain) {
        TypedQuery<E> select = em.createQuery(selectJpql(orderBy), entity);
        TypedQuery<Long> count = em.createQuery(countJpql(), Long.class);
        parameters.forEach((name, value) -> {
            select.setParameter(name, value);
            count.setParameter(name, value);
        });
        List<D> items = select.setFirstResult(PageOffset.of(page, size)).setMaxResults(size).getResultList().stream()
                .map(toDomain).toList();
        return new PageResult<>(items, page, size, count.getSingleResult());
    }

    String selectJpql(String orderBy) {
        return "select " + alias + from() + " order by " + orderBy;
    }

    String countJpql() {
        return "select count(" + alias + ")" + from();
    }

    private String from() {
        String from = " from " + entity.getSimpleName() + " " + alias;
        return conditions.isEmpty() ? from : from + " where " + String.join(" and ", conditions);
    }
}
