package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * The test resources of every {@code @QuarkusTest} of core that runs without Keycloak: Postgres with the production
 * roles and RLS ({@code service=core}) and the WireMock stand-in for Keycloak and the sibling services. One annotation
 * instead of the same two lines on each class (CORET-09): Quarkus reuses a started application only for classes with
 * the same resources, so a class that spelled them differently would cost a restart.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
public @interface CoreTestResources {}
