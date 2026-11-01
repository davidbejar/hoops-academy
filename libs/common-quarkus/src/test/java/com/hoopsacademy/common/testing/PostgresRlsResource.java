package com.hoopsacademy.common.testing;

import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;
import org.testcontainers.utility.MountableFile;

/**
 * Starts {@code postgres:17} with the production bootstrap ({@code infra/db/init/01_roles_schemas.sql} and
 * {@code 02_passwords.sh}) and wires the service so that the default datasource connects as the NON-owner
 * {@code <svc>_app} role while Flyway migrates as {@code <svc>_migrator}.
 *
 * <p>Init args: {@code service} (default {@code core}); {@code initDir} (default: {@code infra/db/init} found by
 * walking up from the working directory, or system property {@code hoops.db.init-dir}).
 *
 * <p>Build-time settings cannot come from a test resource, so the consuming service must declare
 * {@code quarkus.datasource.db-kind=postgresql} and {@code %test.quarkus.datasource.devservices.enabled=false}.
 *
 * <pre>{@code @WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))}</pre>
 */
public class PostgresRlsResource implements QuarkusTestResourceLifecycleManager {

    public static final String SERVICE_ARG = "service";
    public static final String INIT_DIR_ARG = "initDir";
    static final String INIT_DIR_PROPERTY = "hoops.db.init-dir";
    private static final String DEFAULT_SERVICE = "core";
    private static final DockerImageName IMAGE =
            DockerImageName.parse("docker.io/library/postgres:17").asCompatibleSubstituteFor("postgres");
    private static final String INIT_TARGET = "/docker-entrypoint-initdb.d/";

    private String service = DEFAULT_SERVICE;
    private Path initDir;
    private PostgreSQLContainer container;

    @Override
    public void init(Map<String, String> initArgs) {
        service = initArgs.getOrDefault(SERVICE_ARG, DEFAULT_SERVICE);
        String explicitDir = initArgs.getOrDefault(INIT_DIR_ARG, System.getProperty(INIT_DIR_PROPERTY));
        initDir = explicitDir != null ? Path.of(explicitDir) : locateInitDir(Path.of("").toAbsolutePath());
    }

    @Override
    public Map<String, String> start() {
        container = new PostgreSQLContainer(IMAGE)
                .withDatabaseName("hoops")
                .withUsername("postgres")
                .withPassword("postgres")
                .withEnv(TestRolePasswords.asEnvironment())
                .withCopyFileToContainer(
                        MountableFile.forHostPath(initDir.resolve("01_roles_schemas.sql")), INIT_TARGET + "01_roles_schemas.sql")
                .withCopyFileToContainer(
                        MountableFile.forHostPath(initDir.resolve("02_passwords.sh"), 0755), INIT_TARGET + "02_passwords.sh");
        container.start();
        return configFor(container.getJdbcUrl());
    }

    @Override
    public void stop() {
        if (container != null) {
            container.stop();
        }
    }

    Map<String, String> configFor(String jdbcUrl) {
        String appRole = service + "_app";
        String migratorRole = service + "_migrator";
        Map<String, String> config = new HashMap<>();
        config.put("quarkus.datasource.jdbc.url", jdbcUrl);
        config.put("quarkus.datasource.username", appRole);
        config.put("quarkus.datasource.password", TestRolePasswords.of(appRole));
        config.put("quarkus.flyway.migrate-at-start", "true");
        config.put("quarkus.flyway.username", migratorRole);
        config.put("quarkus.flyway.password", TestRolePasswords.of(migratorRole));
        config.put(RlsTestDatabase.SERVICE_KEY, service);
        config.put(RlsTestDatabase.JDBC_URL_KEY, jdbcUrl);
        return config;
    }

    static Path locateInitDir(Path start) {
        for (Path dir = start; dir != null; dir = dir.getParent()) {
            Path candidate = dir.resolve("infra/db/init");
            if (Files.isRegularFile(candidate.resolve("01_roles_schemas.sql"))) {
                return candidate;
            }
        }
        throw new IllegalStateException("infra/db/init not found above " + start
                + "; set -D" + INIT_DIR_PROPERTY + " or the '" + INIT_DIR_ARG + "' init arg");
    }
}
