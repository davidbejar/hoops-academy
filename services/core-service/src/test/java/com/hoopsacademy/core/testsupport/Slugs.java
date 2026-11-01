package com.hoopsacademy.core.testsupport;

import java.util.UUID;

/** Unique, valid tenant slugs so tests never collide in the shared test database. */
public final class Slugs {

    private Slugs() {}

    public static String unique(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }
}
