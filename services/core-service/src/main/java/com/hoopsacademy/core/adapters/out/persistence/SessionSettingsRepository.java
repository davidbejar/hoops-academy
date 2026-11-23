package com.hoopsacademy.core.adapters.out.persistence;

import jakarta.persistence.EntityManager;
import java.util.function.Supplier;

/**
 * The transaction-local settings the RLS policies read ({@code app.tenant_id}, {@code app.subject}), for the few
 * adapters that rebind them with native SQL inside a transaction (ADR-0013, ADR-0026).
 */
public final class SessionSettingsRepository {

    public static final String TENANT = "app.tenant_id";
    public static final String SUBJECT = "app.subject";
    /** Binds no academy: the standard tenant policy then matches nothing instead of raising. */
    public static final String NIL_TENANT = "00000000-0000-0000-0000-000000000000";

    private SessionSettingsRepository() {}

    /** The setting's value in this transaction, {@code ""} when unset. */
    public static String current(EntityManager em, String name) {
        return (String) em.createNativeQuery("select coalesce(current_setting(:name, true), '')")
                .setParameter("name", name)
                .getSingleResult();
    }

    /** Sets {@code name} for the rest of the transaction ({@code set_config(…, true)}). */
    public static void set(EntityManager em, String name, String value) {
        em.createNativeQuery("select set_config(:name, :value, true)")
                .setParameter("name", name)
                .setParameter("value", value)
                .getSingleResult();
    }

    /**
     * Runs {@code statements} with {@code name} bound to {@code value}, then binds {@code restore} again. After a
     * failure the transaction rolls back anyway: a restore that fails on the aborted transaction is added to the
     * failure as suppressed instead of hiding it.
     */
    static <T> T with(EntityManager em, String name, String value, String restore, Supplier<T> statements) {
        set(em, name, value);
        T result;
        try {
            result = statements.get();
        } catch (RuntimeException failure) {
            try {
                set(em, name, restore);
            } catch (RuntimeException restoreFailure) {
                failure.addSuppressed(restoreFailure);
            }
            throw failure;
        }
        set(em, name, restore);
        return result;
    }
}
