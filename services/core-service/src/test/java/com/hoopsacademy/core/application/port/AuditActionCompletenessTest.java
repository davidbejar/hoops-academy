package com.hoopsacademy.core.application.port;

import static org.assertj.core.api.Assertions.assertThat;

import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.parser.OpenAPIV3Parser;
import io.swagger.v3.parser.core.models.ParseOptions;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/**
 * One source for the action names (WP34): {@link AuditEvent} only takes an {@link AuditAction}, and this test keeps
 * the enum, the contract's {@code AuditAction} / {@code AuditTargetType} and {@code docs/domain/audit-events.md}
 * equal, so a new action cannot be recorded without appearing in the contract and the catalogue.
 */
class AuditActionCompletenessTest {

    @Test
    void theContractPublishesExactlyTheRecordedActions() {
        assertThat(contractEnum("AuditAction"))
                .containsExactlyInAnyOrderElementsOf(Arrays.stream(AuditAction.values()).map(AuditAction::wireName).toList());
    }

    @Test
    void theContractPublishesExactlyTheTargetTypes() {
        assertThat(contractEnum("AuditTargetType")).containsExactlyInAnyOrderElementsOf(
                Arrays.stream(AuditTargetType.values()).map(AuditTargetType::wireName).toList());
    }

    @Test
    void theCatalogueListsEveryActionWithItsTargetType() {
        String catalogue = read("docs/domain/audit-events.md");
        for (AuditAction action : AuditAction.values()) {
            Pattern row = Pattern.compile("^\\| `" + Pattern.quote(action.wireName()) + "` \\| "
                    + Pattern.quote(action.targetType().wireName()) + " \\|", Pattern.MULTILINE);
            assertThat(row.matcher(catalogue).find()).as(action.wireName() + " in docs/domain/audit-events.md").isTrue();
        }
    }

    @Test
    void wireNamesAreUniqueAndParseBack() {
        for (AuditAction action : AuditAction.values()) {
            assertThat(AuditAction.fromWireName(action.wireName())).contains(action);
        }
        assertThat(AuditAction.fromWireName("member.unknown")).isEmpty();
        assertThat(AuditTargetType.fromWireName("player")).contains(AuditTargetType.PLAYER);
        assertThat(AuditTargetType.fromWireName("nothing")).isEmpty();
    }

    private static List<String> contractEnum(String schema) {
        try (InputStream in = AuditActionCompletenessTest.class.getResourceAsStream("/openapi/core.yaml")) {
            assertThat(in).as("core.yaml on the test classpath").isNotNull();
            ParseOptions options = new ParseOptions();
            options.setResolve(false);
            Schema<?> enumSchema = new OpenAPIV3Parser()
                    .readContents(new String(in.readAllBytes(), StandardCharsets.UTF_8), null, options)
                    .getOpenAPI().getComponents().getSchemas().get(schema);
            return enumSchema.getEnum().stream().map(String::valueOf).toList();
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    private static String read(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            Path file = dir.resolve(relative);
            if (Files.exists(file)) {
                try {
                    return Files.readString(file);
                } catch (IOException e) {
                    throw new IllegalStateException(e);
                }
            }
        }
        throw new IllegalStateException(relative + " not found");
    }
}
