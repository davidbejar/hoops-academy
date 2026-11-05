package com.hoopsacademy.common.testing;

import io.smallrye.config.PropertiesConfigSource;
import io.smallrye.config.SmallRyeConfig;
import io.smallrye.config.SmallRyeConfigBuilder;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The database users a service ships with: its {@code application.properties} plus library defaults, under the
 * {@code prod} profile, with no environment variables or system properties, so {@code ${CORE_APP_USER:core_app}}
 * resolves to its default. That is what a deployment connects as unless it overrides the user, and nothing in
 * {@code deploy/} does. {@link PostgresRlsResource} replaces the users at test time, so a test that only asks Postgres
 * for {@code current_user} cannot catch a wrong production setting; this can.
 *
 * @param users datasource name ({@link #DEFAULT} for the default one) to username
 * @param flywayUser the user Flyway migrates as (the schema owner)
 */
public record ShippedDatasources(Map<String, String> users, String flywayUser) {

    public static final String DEFAULT = "<default>";

    private static final Pattern USERNAME = Pattern.compile("^quarkus\\.datasource\\.(?:\"([^\"]+)\"\\.|([^.\"]+)\\.)?username$");
    private static final int APPLICATION_ORDINAL = 250;
    private static final int LIBRARY_ORDINAL = 100;

    /**
     * The module's own {@code src/main/resources/application.properties} (surefire runs in the module directory) plus
     * library defaults from the classpath. Not {@code application.properties} from the classpath: under
     * {@code @QuarkusTest} it also holds a generated {@code startup-override/application.properties} with the test
     * resources' values ({@code username=core_app}), which would mask a wrong shipped user.
     */
    public static ShippedDatasources load() {
        Path shipped = Path.of("src/main/resources/application.properties").toAbsolutePath();
        if (!Files.isRegularFile(shipped)) {
            throw new IllegalStateException(shipped + " not found; run from the service module directory");
        }
        ClassLoader loader = Thread.currentThread().getContextClassLoader();
        try {
            return from(List.of(shipped.toUri().toURL()),
                    Collections.list(loader.getResources("META-INF/microprofile-config.properties")));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    public static ShippedDatasources from(URL applicationProperties) {
        return from(List.of(applicationProperties), List.of());
    }

    private static ShippedDatasources from(List<URL> applications, List<URL> libraries) {
        SmallRyeConfigBuilder builder = new SmallRyeConfigBuilder().addDefaultInterceptors().withProfile("prod");
        try {
            for (URL url : applications) {
                builder.withSources(new PropertiesConfigSource(url, APPLICATION_ORDINAL));
            }
            for (URL url : libraries) {
                builder.withSources(new PropertiesConfigSource(url, LIBRARY_ORDINAL));
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        SmallRyeConfig config = builder.build();
        Map<String, String> users = new TreeMap<>();
        for (String name : config.getPropertyNames()) {
            Matcher m = USERNAME.matcher(name);
            if (m.matches()) {
                String datasource = m.group(1) != null ? m.group(1) : m.group(2) != null ? m.group(2) : DEFAULT;
                users.put(datasource, config.getValue(name, String.class));
            }
        }
        return new ShippedDatasources(Map.copyOf(users),
                config.getOptionalValue("quarkus.flyway.username", String.class).orElse(null));
    }
}
