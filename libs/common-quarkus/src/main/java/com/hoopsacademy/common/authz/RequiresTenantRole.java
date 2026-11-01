package com.hoopsacademy.common.authz;

import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.util.Nonbinding;
import jakarta.interceptor.InterceptorBinding;
import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * The caller must hold at least ONE of the given tenant roles (any-of), else 403 Problem. A method-level
 * annotation replaces a class-level one. Non-members never get here: the tenant filter already answered 404.
 */
@Inherited
@InterceptorBinding
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface RequiresTenantRole {

    @Nonbinding
    TenantRole[] value();
}
