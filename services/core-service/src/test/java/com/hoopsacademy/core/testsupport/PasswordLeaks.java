package com.hoopsacademy.core.testsupport;

import static org.assertj.core.api.Assertions.assertThat;

/** Proves that a temporary password (ADR-0024) reached neither the database nor the logs. */
public final class PasswordLeaks {

    private PasswordLeaks() {}

    public static void assertNeverStoredOrLogged(String tenant, String password, LogCapture logs) {
        assertThat(password).as("temporary password").hasSize(16);
        assertThat(CoreDb.tablesContaining(tenant, password)).as("core tables containing the temporary password")
                .isEmpty();
        assertThat(logs.containing(password)).as("log lines containing the temporary password").isEmpty();
    }
}
