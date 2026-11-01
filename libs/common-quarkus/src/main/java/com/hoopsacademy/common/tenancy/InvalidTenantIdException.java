package com.hoopsacademy.common.tenancy;

/** A tenant identifier could not be parsed. The message never echoes the raw input. */
public class InvalidTenantIdException extends IllegalArgumentException {

    public InvalidTenantIdException(String reason) {
        super("Invalid tenant id: " + reason);
    }
}
