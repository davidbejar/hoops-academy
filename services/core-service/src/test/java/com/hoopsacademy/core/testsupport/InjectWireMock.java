package com.hoopsacademy.core.testsupport;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/** Injects the {@link WireMockResource} server into a {@code WireMockServer} field of a {@code @QuarkusTest}. */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface InjectWireMock {}
