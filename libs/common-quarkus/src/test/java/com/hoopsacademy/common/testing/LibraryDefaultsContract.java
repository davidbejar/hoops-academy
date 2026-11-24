package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.replica.RosterTopic;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.Map;
import java.util.Properties;
import java.util.TreeMap;
import org.junit.jupiter.api.Test;

/**
 * The settings every Quarkus service shares live once, in common-quarkus' {@code META-INF/microprofile-config.properties}
 * (WP137, ADR-0069). A service extends this class to show that it still sees them as it ships, and that its own
 * {@code application.properties} does not restate one of the library's values (a restated default hides which value is
 * authoritative and drifts when the library changes). A service may still override a library key with another value.
 */
public abstract class LibraryDefaultsContract {

    private static final String LIBRARY_FILE = "META-INF/microprofile-config.properties";
    private static final String LIBRARY_MARKER = "common-quarkus";
    /** Where {@code just up} serves the realm (ADR-0071): {@code quarkus:dev} needs no variable against compose. */
    private static final String REALM_DEFAULT = "http://localhost:8080/auth/realms/academy";

    /** The keys moved out of the three services' files, with the value each service must see in production. */
    private static final Map<String, String> SHARED_IN_PRODUCTION = Map.ofEntries(
            Map.entry("quarkus.datasource.db-kind", "postgresql"),
            Map.entry("quarkus.flyway.create-schemas", "false"),
            Map.entry("quarkus.hibernate-orm.schema-management.strategy", "none"),
            Map.entry("quarkus.oidc.roles.role-claim-path", "realm_access/roles"),
            Map.entry("quarkus.oidc.auth-server-url", REALM_DEFAULT),
            Map.entry("quarkus.oidc-client.auth-server-url", REALM_DEFAULT),
            Map.entry("quarkus.oidc-client.early-tokens-acquisition", "false"),
            Map.entry("kafka.bootstrap.servers", "localhost:19092"),
            Map.entry("kafka.security.protocol", "PLAINTEXT"),
            Map.entry("kafka.sasl.mechanism", "SCRAM-SHA-256"),
            Map.entry("quarkus.otel.logs.enabled", "true"),
            Map.entry("quarkus.otel.traces.sampler", "parentbased_traceidratio"),
            Map.entry("quarkus.datasource.jdbc.telemetry", "true"));

    /** The test-profile keys moved out of the three services' files. */
    private static final Map<String, String> SHARED_IN_TESTS = Map.of(
            "quarkus.oidc.tenant-enabled", "false",
            "quarkus.oidc-client.discovery-enabled", "false",
            "quarkus.jacoco.data-file", "target/jacoco.exec",
            "quarkus.jacoco.reuse-data-file", "true",
            "quarkus.jacoco.report", "false",
            "hoops.security.require-sub", "false");

    @Test
    void theServiceSeesTheSharedSettingsInProduction() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of());

        SHARED_IN_PRODUCTION.forEach((key, value) -> assertThat(prod.value(key)).as(key).contains(value));
    }

    @Test
    void oneVariableNamesTheRealmForTokenValidationAndServiceTokens() {
        String realm = "https://sso.example/auth/realms/academy";
        ShippedConfig prod = ShippedConfig.load("prod",
                Map.of("OIDC_AUTH_SERVER_URL", realm, "KEYCLOAK_URL", "http://retired.example"));

        assertThat(prod.value("quarkus.oidc.auth-server-url")).contains(realm);
        assertThat(prod.value("quarkus.oidc-client.auth-server-url")).contains(realm);
    }

    @Test
    void theServiceSeesTheSharedTestSettings() {
        ShippedConfig test = ShippedConfig.load("test", Map.of());

        SHARED_IN_TESTS.forEach((key, value) -> assertThat(test.value(key)).as(key).contains(value));
        assertThat(test.value("kafka.bootstrap.servers")).as("the test broker sets it").isEmpty();
    }

    @Test
    void devServicesCreateEveryRosterTopicWithOnePartition() {
        ShippedConfig dev = ShippedConfig.load("dev", Map.of());

        RosterTopic.topicNames().forEach(topic -> assertThat(
                dev.value("quarkus.kafka.devservices.topic-partitions.\"" + topic + "\"")).as(topic).contains("1"));
    }

    @Test
    void theServiceDoesNotRestateALibraryValue() {
        Properties library = load(libraryFile());
        Properties service = load(serviceFile());

        Map<String, String> restated = new TreeMap<>();
        for (String key : service.stringPropertyNames()) {
            if (service.getProperty(key).equals(library.getProperty(key))) {
                restated.put(key, service.getProperty(key));
            }
        }
        assertThat(restated).as("keys whose value the library already ships").isEmpty();
    }

    private static URL serviceFile() {
        Path shipped = Path.of("src/main/resources/application.properties").toAbsolutePath();
        if (!Files.isRegularFile(shipped)) {
            throw new IllegalStateException(shipped + " not found; run from the service module directory");
        }
        try {
            return shipped.toUri().toURL();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static URL libraryFile() {
        try {
            return Collections.list(Thread.currentThread().getContextClassLoader().getResources(LIBRARY_FILE)).stream()
                    .filter(url -> url.toString().contains(LIBRARY_MARKER))
                    .findFirst()
                    .orElseThrow(() -> new IllegalStateException("common-quarkus' " + LIBRARY_FILE + " not found"));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static Properties load(URL url) {
        Properties properties = new Properties();
        try (InputStream in = url.openStream()) {
            properties.load(in);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return properties;
    }
}
