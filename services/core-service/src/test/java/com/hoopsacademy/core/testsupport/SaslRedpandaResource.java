package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.testing.ContainerStarts;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.eclipse.microprofile.config.ConfigProvider;
import org.testcontainers.containers.Container.ExecResult;
import org.testcontainers.redpanda.RedpandaContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * A broker like the chart's (WP71): the pinned Redpanda image of Dev Services, its Kafka listener requiring SASL/SCRAM,
 * the seven {@code core.*} topics, and no user yet. core starts with the credentials of {@link #USER}, so its first
 * login fails like a fresh Helm install before the bootstrap Job; {@link #createCoreUser()} is that Job. Pair with a
 * profile that turns Kafka Dev Services off.
 */
public class SaslRedpandaResource implements QuarkusTestResourceLifecycleManager {

    public static final String USER = "core-service";
    private static final String PASSWORD = "sasl-test-only-password";
    private static final List<String> TOPICS = List.of("core.person", "core.player", "core.team", "core.team-player",
            "core.team-staff", "core.guardian-link", "core.tenant");

    private static RedpandaContainer broker;

    @Override
    public Map<String, String> start() {
        String image = ConfigProvider.getConfig().getValue("quarkus.kafka.devservices.image-name", String.class);
        // docker.io/redpandadata/redpanda is the image Testcontainers expects under another registry name
        broker = new RedpandaContainer(DockerImageName.parse(image).asCompatibleSubstituteFor("redpandadata/redpanda"))
                .enableSasl();
        ContainerStarts.start(broker);   // WP87: survives Docker API connections closed while idle
        List<String> create = new ArrayList<>(List.of("rpk", "topic", "create"));
        create.addAll(TOPICS);
        create.addAll(List.of("-p", "1", "-c", "cleanup.policy=compact"));
        rpk(create.toArray(String[]::new));
        return Map.of(
                "kafka.bootstrap.servers", broker.getHost() + ":" + broker.getMappedPort(9092),
                "kafka.security.protocol", "SASL_PLAINTEXT",
                "kafka.sasl.mechanism", "SCRAM-SHA-256",
                "kafka.sasl.jaas.config", "org.apache.kafka.common.security.scram.ScramLoginModule required username=\""
                        + USER + "\" password=\"" + PASSWORD + "\";");
    }

    /** What the chart's bootstrap Job does for core: the SCRAM user with the password core already has. */
    public static void createCoreUser() {
        rpk("rpk", "security", "user", "create", USER, "-p", PASSWORD, "--mechanism", "SCRAM-SHA-256");
    }

    private static void rpk(String... command) {
        try {
            ExecResult result = broker.execInContainer(command);
            if (result.getExitCode() != 0) {
                throw new IllegalStateException(String.join(" ", command) + " failed: " + result.getStderr()
                        + result.getStdout());
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    @Override
    public void stop() {
        if (broker != null) {
            broker.stop();
        }
    }
}
