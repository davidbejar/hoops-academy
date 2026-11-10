package com.hoopsacademy.common.testing;

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
 * The broker of the test classes that run the roster replica consumer of game or athlete (WP82; one copy in the
 * test-jar since WP98): the pinned Redpanda image of the Kafka Dev Services, started through {@link ContainerStarts}
 * (Dev Services start their container without it, the WP87 "localhost:2375 failed to respond" flake), with the seven
 * {@code core.*} topics of one partition each, and the consumer switched on ({@code hoops.roster.consumer.enabled}, off
 * in the services' test profile, which needs no broker). A consumer needs {@code testcontainers-redpanda} as a test
 * dependency.
 */
public class RosterBrokerResource implements QuarkusTestResourceLifecycleManager {

    /** The roster topics, as {@code infra/compose/redpanda-topics.sh} and the chart create them. */
    static final List<String> TOPICS = List.of("core.person", "core.player", "core.team", "core.team-player",
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
        return Map.of("kafka.bootstrap.servers", broker.getBootstrapServers(), "hoops.roster.consumer.enabled", "true");
    }

    /** Runs an {@code rpk} command in the broker; @return its standard output */
    String rpk(String... command) {
        try {
            ExecResult result = broker.execInContainer(command);
            if (result.getExitCode() != 0) {
                throw new IllegalStateException(String.join(" ", command) + " failed: " + result.getStderr()
                        + result.getStdout());
            }
            return result.getStdout();
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
