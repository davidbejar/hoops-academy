package com.hoopsacademy.core.application.port;

/** The identity provider failed or is unreachable (mapped to 502). */
public class IdentityProviderException extends RuntimeException {

    public IdentityProviderException(String message, Throwable cause) {
        super(message, cause);
    }

    public IdentityProviderException(String message) {
        super(message);
    }
}
