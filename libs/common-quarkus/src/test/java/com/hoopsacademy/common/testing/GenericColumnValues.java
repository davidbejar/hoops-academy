package com.hoopsacademy.common.testing;

import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Type-driven placeholder values (as SQL literals cast by the insert) for columns without an override. */
final class GenericColumnValues {

    private static final Pattern LENGTH = Pattern.compile("\\((\\d+)\\)");

    private GenericColumnValues() {}

    static Optional<String> forType(String sqlType) {
        if (sqlType.equals("uuid")) {
            return Optional.of(UUID.randomUUID().toString());
        }
        if (sqlType.startsWith("character") || sqlType.equals("text") || sqlType.equals("citext")) {
            return Optional.of(randomText(maxLength(sqlType)));
        }
        if (sqlType.equals("smallint") || sqlType.equals("integer") || sqlType.equals("bigint")) {
            return Optional.of(Integer.toString(ThreadLocalRandom.current().nextInt(1, 30_000)));
        }
        if (sqlType.startsWith("numeric") || sqlType.equals("real") || sqlType.equals("double precision")) {
            return Optional.of("1");
        }
        return Optional.ofNullable(switch (sqlType) {
            case "boolean" -> "false";
            case "date" -> "2026-01-01";
            case "timestamp without time zone", "timestamp with time zone" -> "2026-01-01 12:00:00";
            case "time without time zone" -> "12:00:00";
            case "json", "jsonb" -> "{}";
            case "bytea" -> "\\x00";
            default -> null;
        });
    }

    private static int maxLength(String sqlType) {
        Matcher matcher = LENGTH.matcher(sqlType);
        return matcher.find() ? Integer.parseInt(matcher.group(1)) : 16;
    }

    private static String randomText(int maxLength) {
        byte[] bytes = new byte[8];
        ThreadLocalRandom.current().nextBytes(bytes);
        String text = "rls" + HexFormat.of().formatHex(bytes);
        return text.substring(0, Math.min(text.length(), maxLength));
    }
}
