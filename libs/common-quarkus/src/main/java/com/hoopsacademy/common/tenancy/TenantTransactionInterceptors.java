package com.hoopsacademy.common.tenancy;

import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.interceptor.AroundInvoke;
import jakarta.interceptor.Interceptor;
import jakarta.interceptor.InvocationContext;
import jakarta.transaction.Transactional;
import jakarta.transaction.Transactional.TxType;

/**
 * Interceptors bound to {@code @Transactional} that run just inside Narayana's transaction interceptors
 * (priority 200) and bind the context tenant to the transaction. {@code TxType} is a binding member, hence one
 * interceptor per type that can have an active transaction. NOT_SUPPORTED/NEVER never have one.
 */
public final class TenantTransactionInterceptors {

    /** Runs right after Narayana (PLATFORM_BEFORE + 200) has begun or joined the transaction. */
    static final int PRIORITY = Interceptor.Priority.PLATFORM_BEFORE + 210;

    private TenantTransactionInterceptors() {}

    abstract static class Base {

        @Inject
        TenantTransactions tenantTransactions;

        @AroundInvoke
        Object bindTenant(InvocationContext invocation) throws Exception {
            tenantTransactions.bindCurrentTransaction();
            return invocation.proceed();
        }
    }

    @Interceptor
    @Transactional(TxType.REQUIRED)
    @Priority(PRIORITY)
    static class Required extends Base {}

    @Interceptor
    @Transactional(TxType.REQUIRES_NEW)
    @Priority(PRIORITY)
    static class RequiresNew extends Base {}

    @Interceptor
    @Transactional(TxType.MANDATORY)
    @Priority(PRIORITY)
    static class Mandatory extends Base {}

    @Interceptor
    @Transactional(TxType.SUPPORTS)
    @Priority(PRIORITY)
    static class Supports extends Base {}
}
