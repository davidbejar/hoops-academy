package com.hoopsacademy.core.testsupport;

import com.github.dockerjava.api.DockerClient;
import com.github.dockerjava.api.model.Container;
import com.github.dockerjava.api.model.ContainerPort;
import java.util.Arrays;
import java.util.Objects;
import org.eclipse.microprofile.config.ConfigProvider;
import org.testcontainers.DockerClientFactory;

/**
 * Pauses and resumes the Dev Services Redpanda container: a broker that stops answering, then comes back. Paused
 * containers are listed only with {@code showAll}.
 */
public final class DevServicesBroker {

    private DevServicesBroker() {}

    public static void pause() {
        docker().pauseContainerCmd(containerId()).exec();
    }

    public static void resume() {
        docker().unpauseContainerCmd(containerId()).exec();
    }

    private static String containerId() {
        String bootstrap = ConfigProvider.getConfig().getValue("kafka.bootstrap.servers", String.class);
        int port = Integer.parseInt(bootstrap.substring(bootstrap.lastIndexOf(':') + 1));
        return docker().listContainersCmd().withShowAll(true).exec().stream()
                .filter(container -> publishes(container, port))
                .map(Container::getId)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("No container publishes the broker port " + port));
    }

    private static boolean publishes(Container container, int port) {
        return Arrays.stream(container.getPorts()).map(ContainerPort::getPublicPort).filter(Objects::nonNull)
                .anyMatch(published -> published == port);
    }

    private static DockerClient docker() {
        return DockerClientFactory.instance().client();
    }
}
