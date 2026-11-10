package com.hoopsacademy.common.testing;

import io.smallrye.config.EnvConfigSource;
import io.smallrye.config.PropertiesConfigSource;
import io.smallrye.config.SmallRyeConfig;
import io.smallrye.config.SmallRyeConfigBuilder;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;

/**
 * A setting as a service ships it (WP98): the module's own {@code src/main/resources/application.properties} plus the
 * libraries' {@code META-INF/microprofile-config.properties}, under one profile ({@code prod}, {@code dev},
 * {@code test}) and with only the given environment variables, so {@code ${GAME_ROSTER_SOURCE:replica}} resolves to its
 * default unless the test sets it. Read from the source file for the reason {@link ShippedDatasources} gives: under
 * {@code @QuarkusTest} the classpath also carries the test resources' overrides.
 */
public final class ShippedConfig {

    private static final int ENVIRONMENT_ORDINAL = 300;
    private static final int APPLICATION_ORDINAL = 250;
    private static final int LIBRARY_ORDINAL = 100;

    private final SmallRyeConfig config;

    private ShippedConfig(SmallRyeConfig config) {
        this.config = config;
    }

    /** Run from the service module directory (surefire's working directory). */
    public static ShippedConfig load(String profile, Map<String, String> environment) {
        Path shipped = Path.of("src/main/resources/application.properties").toAbsolutePath();
        if (!Files.isRegularFile(shipped)) {
            throw new IllegalStateException(shipped + " not found; run from the service module directory");
        }
        SmallRyeConfigBuilder builder = new SmallRyeConfigBuilder().addDefaultInterceptors().withProfile(profile)
                .withSources(new EnvConfigSource(environment, ENVIRONMENT_ORDINAL));
        try {
            builder.withSources(new PropertiesConfigSource(shipped.toUri().toURL(), APPLICATION_ORDINAL));
            for (URL library : Collections.list(Thread.currentThread().getContextClassLoader()
                    .getResources("META-INF/microprofile-config.properties"))) {
                builder.withSources(new PropertiesConfigSource(library, LIBRARY_ORDINAL));
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return new ShippedConfig(builder.build());
    }

    public Optional<String> value(String name) {
        return config.getOptionalValue(name, String.class);
    }
}
