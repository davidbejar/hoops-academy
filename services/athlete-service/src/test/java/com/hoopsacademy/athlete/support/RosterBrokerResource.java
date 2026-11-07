package com.hoopsacademy.athlete.support;

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
 * The broker of the test classes that run the roster consumer (WP82): the pinned Redpanda image of the Kafka Dev
 * Services, started through {@link ContainerStarts} (Dev Services start their container without it, the WP87
 * "localhost:2375 failed to respond" flake), with the seven {@code core.*} topics of one partition each, and the
 * consumer switched on (it is off in the test profile, which needs no broker; {@code ReplicaProfile} adds it).
 */
public class RosterBrokerResource implements QuarkusTestResourceLifecycleManager {

    private static final List<String> TOPICS = List.of("core.person", "core.player", "core.team", "core.team-player",
            "core.team-staff", "core.guardian-link", "core.tenant");

    private RedpandaContainer broker;

    @Override
    public Map<String, String> start() {
        String image = ConfigProvider.getConfig().getValue("quarkus.kafka.devservices.image-name", String.class);
        broker = new RedpandaContainer(DockerImageName.parse(image).asCompatibleSubstituteFor("redpandadata/redpanda"));
        ContainerStarts.start(broker);
        List<String> create = new ArrayList<>(List.of("rpk", "topic", "create"));
        create.addAll(TOPICS);
        create.addAll(List.of("-p", "1"));
        rpk(create.toArray(String[]::new));
        return Map.of("kafka.bootstrap.servers", broker.getBootstrapServers(),
                "hoops.roster.consumer.enabled", "true");
    }

    private void rpk(String... command) {
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
