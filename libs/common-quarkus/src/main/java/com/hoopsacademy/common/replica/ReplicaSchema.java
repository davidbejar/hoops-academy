package com.hoopsacademy.common.replica;

import java.util.Objects;
import java.util.regex.Pattern;

/**
 * The database schema of a service's replica tables ({@code game}, {@code athlete}): a plain lower-case identifier, so
 * the shared stores can name their tables in SQL text without quoting.
 */
public record ReplicaSchema(String name) {

    private static final Pattern IDENTIFIER = Pattern.compile("^[a-z][a-z_]*$");

    public ReplicaSchema {
        Objects.requireNonNull(name, "name");
        if (!IDENTIFIER.matcher(name).matches()) {
            throw new IllegalArgumentException("not a plain schema name: " + name);
        }
    }

    /** @param table a table of the replica bookkeeping, e.g. {@code parked_event} */
    String table(String table) {
        return name + "." + table;
    }
}
