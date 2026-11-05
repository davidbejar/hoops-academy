package com.hoopsacademy.archfixture.mutationscope;

import io.quarkus.test.junit.QuarkusTest;

/** Boots Quarkus (and its Dev Services); no test methods, so surefire never starts it. */
@QuarkusTest
public class ContainerBackedCheck {

    public class NestedCheck {}
}
