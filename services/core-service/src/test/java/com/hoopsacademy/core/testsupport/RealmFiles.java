package com.hoopsacademy.core.testsupport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.testing.TestRealm;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;

/** The shipped realm export as the realm and theme tests read it (found from the module directory by common's walker). */
public final class RealmFiles {

    /** The realm export of {@code infra/keycloak}, relative to the repository root. */
    public static final String REALM = "infra/keycloak/realm-academy.json";

    private RealmFiles() {}

    /** The realm JSON at {@code relative}, its {@code ${PLACEHOLDER}}s (filled at deploy time) replaced by a word. */
    public static JsonNode realmJson(String relative) {
        try {
            return new ObjectMapper().readTree(Files.readString(TestRealm.locate(relative))
                    .replaceAll("\\$\\{[A-Z_]+}", "placeholder"));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
