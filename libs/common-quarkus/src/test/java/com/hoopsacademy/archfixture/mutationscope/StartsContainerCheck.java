package com.hoopsacademy.archfixture.mutationscope;

import org.testcontainers.containers.PostgreSQLContainer;

/** Starts a container by hand, without any Quarkus annotation. */
public class StartsContainerCheck {

    PostgreSQLContainer<?> database;
}
