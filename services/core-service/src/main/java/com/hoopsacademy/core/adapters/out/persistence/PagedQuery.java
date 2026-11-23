package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.util.List;
import java.util.Optional;
import java.util.function.Function;

/**
 * One page of a JPQL list: the items query ({@code select … from … where … order by …}, offset and limit) and its
 * count query share the {@code from} clause and the {@link QueryConditions}.
 */
public final class PagedQuery {

    private final EntityManager em;
    private final String from;
    private final String counted;
    private final QueryConditions conditions = new QueryConditions();
    private String orderBy = "";

    private PagedQuery(EntityManager em, String from, String counted) {
        this.em = em;
        this.from = from;
        this.counted = counted;
    }

    /**
     * @param from    the JPQL from clause with its aliases, e.g. {@code "from PlayerEntity p, PersonEntity pe"}
     * @param counted what the count query counts, e.g. {@code "p"}
     */
    public static PagedQuery of(EntityManager em, String from, String counted) {
        return new PagedQuery(em, from, counted);
    }

    public PagedQuery where(String condition) {
        conditions.add(condition);
        return this;
    }

    public PagedQuery where(String condition, String name, Object value) {
        conditions.add(condition, name, value);
        return this;
    }

    public <T> PagedQuery whereIf(Optional<T> value, String condition, String name, Function<? super T, ?> parameter) {
        conditions.addIf(value, condition, name, parameter);
        return this;
    }

    public PagedQuery orderBy(String order) {
        this.orderBy = " order by " + order;
        return this;
    }

    /** The page, each row mapped by {@code map}. */
    public <E, R> PageResult<R> page(PageRequest page, String select, Class<E> type, Function<? super E, R> map) {
        return pageOfRows(page, select, type, rows -> rows.stream().<R>map(map).toList());
    }

    /** The page, the rows mapped together (e.g. to load their children with one more query). */
    public <E, R> PageResult<R> pageOfRows(PageRequest page, String select, Class<E> type,
            Function<List<E>, List<R>> map) {
        TypedQuery<E> items = em.createQuery(select + " " + from + conditions.where() + orderBy, type);
        TypedQuery<Long> total = em.createQuery("select count(" + counted + ") " + from + conditions.where(),
                Long.class);
        conditions.bind(items);
        conditions.bind(total);
        List<E> rows = items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultList();
        return new PageResult<>(map.apply(rows), page, total.getSingleResult());
    }
}
