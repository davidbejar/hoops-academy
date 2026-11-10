package com.hoopsacademy.common.contracts;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;

/**
 * Reads the JSON documents of {@code libs/contracts} (the event and match-event JSON Schemas) from the classpath. The
 * decoders do it once at startup, so a build without the contracts jar fails the start with a message naming the
 * resource (WP98; WP88 had left a {@code NullPointerException}).
 */
public final class ContractResources {

    private ContractResources() {}

    /**
     * @param anchor the class whose class loader resolves the resource (the decoder's own)
     * @param resource an absolute resource path, e.g. {@code /events/core.person.schema.json}
     * @throws IllegalStateException when the resource is not on the classpath
     * @throws UncheckedIOException when it cannot be read or is not JSON
     */
    public static JsonNode json(ObjectMapper mapper, Class<?> anchor, String resource) {
        try (InputStream in = anchor.getResourceAsStream(resource)) {
            if (in == null) {
                throw new IllegalStateException(resource + " is not on the classpath (is the contracts jar a dependency?)");
            }
            return mapper.readTree(in);
        } catch (IOException e) {
            throw new UncheckedIOException(resource + " is not readable JSON", e);
        }
    }
}
