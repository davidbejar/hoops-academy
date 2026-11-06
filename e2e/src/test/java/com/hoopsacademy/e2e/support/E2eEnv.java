package com.hoopsacademy.e2e.support;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/**
 * Configuration of the suite: base URL (system property {@code e2e.baseUrl} or env {@code E2E_BASE_URL}) and
 * secrets, read from the process environment first and the repo's git-ignored {@code .env} second. Values are never
 * logged.
 */
public final class E2eEnv {

    private static final Map<String, String> DOT_ENV = loadDotEnv();

    private E2eEnv() {}

    /** Empty when the suite is not enabled. */
    public static String baseUrl() {
        String v = System.getProperty("e2e.baseUrl");
        if (v == null || v.isBlank()) {
            v = System.getenv("E2E_BASE_URL");
        }
        return v == null ? "" : v.replaceAll("/+$", "");
    }

    public static boolean enabled() {
        return !baseUrl().isEmpty();
    }

    /** SMTP sink API (MailHog on compose, Mailpit on kind; {@link MailSink} detects which). */
    public static String mailUrl() {
        String v = System.getenv("E2E_MAILHOG_URL");
        return (v == null || v.isBlank()) ? "http://localhost:8025" : v.replaceAll("/+$", "");
    }

    public static Path contractsDir() {
        String v = System.getProperty("e2e.contractsDir");
        return Path.of(v == null || v.isBlank() ? "../libs/contracts/openapi" : v).toAbsolutePath().normalize();
    }

    /** A required secret/setting; the message names the variable, never a value. */
    public static String required(String name) {
        String v = System.getenv(name);
        if (v == null || v.isBlank()) {
            v = DOT_ENV.get(name);
        }
        if (v == null || v.isBlank()) {
            throw new IllegalStateException("missing " + name + " (process environment or .env)");
        }
        return v;
    }

    private static Map<String, String> loadDotEnv() {
        Map<String, String> m = new HashMap<>();
        String f = System.getProperty("e2e.envFile");
        Path p = Path.of(f == null || f.isBlank() ? "../.env" : f);
        if (Files.isRegularFile(p)) {
            try {
                for (String line : Files.readAllLines(p)) {
                    String t = line.strip();
                    int eq = t.indexOf('=');
                    if (t.isEmpty() || t.startsWith("#") || eq < 1) {
                        continue;
                    }
                    String val = t.substring(eq + 1).strip();
                    if (val.length() > 1 && (val.startsWith("\"") && val.endsWith("\"") || val.startsWith("'") && val.endsWith("'"))) {
                        val = val.substring(1, val.length() - 1);
                    }
                    m.put(t.substring(0, eq).strip(), val);
                }
            } catch (IOException e) {
                throw new IllegalStateException("cannot read " + p, e);
            }
        }
        return m;
    }
}
