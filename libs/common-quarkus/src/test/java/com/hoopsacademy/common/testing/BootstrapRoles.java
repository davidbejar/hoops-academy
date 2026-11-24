package com.hoopsacademy.common.testing;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The service roles of {@code infra/db/init/01_roles_schemas.sql}, read from its one list (the rows between
 * {@code -- roles: begin} and {@code -- roles: end}, INF-03), so the harness never keeps a copy of the names.
 */
final class BootstrapRoles {

    private static final Pattern LIST = Pattern.compile("(?s)-- roles: begin\\n(.*?)-- roles: end\\n");
    private static final Pattern ROW = Pattern.compile("(?m)^\\s*\\('([a-z_]+)'");

    private BootstrapRoles() {}

    static List<String> in(Path initDir) {
        Path sql = initDir.resolve("01_roles_schemas.sql");
        String text;
        try {
            text = Files.readString(sql);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        Matcher list = LIST.matcher(text);
        if (!list.find()) {
            throw new IllegalStateException("no '-- roles: begin' / '-- roles: end' list in " + sql);
        }
        return ROW.matcher(list.group(1)).results().map(row -> row.group(1)).toList();
    }
}
