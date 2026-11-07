package com.hoopsacademy.athlete.application.replica;

/** Where a parked record sits in its topic: what the retention job logs of a parked row it deleted (never its key). */
public record ParkedPosition(String topic, int partition, long offset) {

    @Override
    public String toString() {
        return topic + "-" + partition + "@" + offset;
    }
}
