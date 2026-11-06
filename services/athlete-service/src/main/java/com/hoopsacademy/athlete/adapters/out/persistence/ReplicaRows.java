package com.hoopsacademy.athlete.adapters.out.persistence;

import java.sql.Date;
import java.time.LocalDate;
import java.util.UUID;

/** Column values of native replica queries, whatever Java type the driver hands back. */
final class ReplicaRows {

    private ReplicaRows() {}

    static UUID uuid(Object value) {
        return value instanceof UUID id ? id : UUID.fromString(value.toString());
    }

    static LocalDate date(Object value) {
        if (value == null) {
            return null;
        }
        return value instanceof Date sqlDate ? sqlDate.toLocalDate() : (LocalDate) value;
    }
}
