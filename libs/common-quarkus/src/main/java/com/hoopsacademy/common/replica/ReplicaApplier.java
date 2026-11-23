package com.hoopsacademy.common.replica;

/** A service's use case that applies one valid event to its replica, in the event's tenant (ADR-0037). */
@FunctionalInterface
public interface ReplicaApplier<E> {

    ReplicaOutcome apply(E event);
}
