package com.hoopsacademy.common.security;

/** The caller of the current request as the tenancy layer bound it (implemented by the tenancy package). */
public interface SecurityCallerSource {

    /** The caller, {@link SecurityCaller#UNKNOWN} outside a request. */
    SecurityCaller current();
}
