package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * The {@code hoops} login theme tells a disabled login that its temporary password expired (ADR-0028): the sweep is
 * the only thing that disables logins, and the theme cannot tell other disabled accounts apart, so the key Keycloak
 * shows for any disabled account ({@code accountDisabledMessage}) carries this text in every app language. The Helm
 * chart ships the same files (copies kept in sync by {@code scripts/sync-chart-files.sh}).
 */
class LoginThemeMessagesTest {

    private static final String THEME = "infra/keycloak/themes/hoops/login/messages/messages_%s.properties";
    private static final String CHART = "deploy/helm/hoops/charts/keycloak/files/theme/messages_%s.properties";

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "en | Your temporary password has expired. Ask your academy administrator for a new one.",
            "es | Tu contraseña temporal ha caducado. Pide una nueva al administrador de tu academia.",
            "id | Kata sandi sementara Anda sudah kedaluwarsa. Mintalah yang baru kepada administrator akademi Anda."})
    void aDisabledLoginIsToldThatItsTemporaryPasswordExpired(String locale, String message) throws IOException {
        Path theme = locate(THEME.formatted(locale));

        assertThat(load(theme).getProperty("accountDisabledMessage")).isEqualTo(message);
        assertThat(Files.readString(theme, StandardCharsets.ISO_8859_1)).as("ASCII only, \\u escapes")
                .matches("\\p{ASCII}*");
        assertThat(locate(CHART.formatted(locale))).hasSameBinaryContentAs(theme);
    }

    private static Properties load(Path file) throws IOException {
        Properties properties = new Properties();
        try (Reader reader = Files.newBufferedReader(file, StandardCharsets.UTF_8)) {
            properties.load(reader);
        }
        return properties;
    }

    private static Path locate(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            if (Files.exists(dir.resolve(relative))) {
                return dir.resolve(relative);
            }
        }
        throw new AssertionError(relative + " not found");
    }
}
