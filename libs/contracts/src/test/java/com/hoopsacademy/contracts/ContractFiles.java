package com.hoopsacademy.contracts;

import java.nio.file.Files;
import java.nio.file.Path;

/** Locates the contract files of this module (system property set by surefire, module dir as fallback). */
final class ContractFiles {

    static final String TENANT_HEADER = "X-Tenant-Id";

    private ContractFiles() {
    }

    static Path moduleDir() {
        Path dir = Path.of(System.getProperty("contracts.dir", "."));
        if (!Files.isDirectory(dir.resolve("openapi"))) {
            throw new IllegalStateException("contracts module directory not found: " + dir.toAbsolutePath());
        }
        return dir;
    }

    static Path openApi(String service) {
        return moduleDir().resolve("openapi").resolve(service + ".yaml");
    }

    static Path matchEventSchema() {
        return moduleDir().resolve("events").resolve("match-event.schema.json");
    }

    static Path validMatchEventExamples() {
        return moduleDir().resolve("events").resolve("examples").resolve("match-events.valid.json");
    }
}
