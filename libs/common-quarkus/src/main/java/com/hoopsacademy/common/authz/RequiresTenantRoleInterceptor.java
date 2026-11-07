package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.problem.TenantRoleDeniedException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.annotation.Priority;
import jakarta.interceptor.AroundInvoke;
import jakarta.interceptor.Interceptor;
import jakarta.interceptor.InvocationContext;
import java.util.Arrays;
import java.util.List;

/**
 * Enforces {@link RequiresTenantRole}; runs before transactions start (Narayana is PLATFORM_BEFORE + 200). A refusal is a
 * {@link TenantRoleDeniedException}, which the Problem mapper answers 403 and logs as a {@code role} security event.
 */
@RequiresTenantRole({})
@Interceptor
@Priority(Interceptor.Priority.PLATFORM_BEFORE + 100)
public class RequiresTenantRoleInterceptor {

    private final TenantContext tenantContext;

    public RequiresTenantRoleInterceptor(TenantContext tenantContext) {
        this.tenantContext = tenantContext;
    }

    @AroundInvoke
    Object authorize(InvocationContext invocation) throws Exception {
        List<TenantRole> anyOf =
                Arrays.asList(invocation.getInterceptorBinding(RequiresTenantRole.class).value());
        AuthzContext caller = tenantContext.authz()
                .orElseThrow(() -> new TenantRoleDeniedException("No tenant membership in the current context"));
        if (!caller.hasAnyRole(anyOf)) {
            throw new TenantRoleDeniedException("Requires one of " + anyOf);
        }
        return invocation.proceed();
    }
}
