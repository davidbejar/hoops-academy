package com.hoopsacademy.common.replica;

/**
 * One record of a core topic as the consumer received it (the Kafka record's coordinates, key and value; a null value is
 * a tombstone).
 */
public record ReplicaRecord(String topic, int partition, long offset, String key, String value) {}
