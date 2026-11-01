package com.hoopsacademy.core.domain.logo;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import java.util.stream.Stream;
import org.junit.jupiter.params.provider.Arguments;

class LogoImageTest {

    public static final byte[] PNG = bytes(0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 'I', 'H', 'D', 'R');
    public static final byte[] JPEG = bytes(0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 'J', 'F', 'I', 'F', 0);
    public static final byte[] WEBP = bytes('R', 'I', 'F', 'F', 0x24, 0, 0, 0, 'W', 'E', 'B', 'P', 'V', 'P', '8', ' ');
    public static final byte[] GIF = "GIF89a\u0001\u0000\u0001\u0000".getBytes(StandardCharsets.ISO_8859_1);
    public static final byte[] SVG =
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><script>alert(1)</script></svg>".getBytes(StandardCharsets.UTF_8);

    static Stream<Arguments> supported() {
        return Stream.of(
                Arguments.of(PNG, ImageFormat.PNG, "image/png"),
                Arguments.of(JPEG, ImageFormat.JPEG, "image/jpeg"),
                Arguments.of(WEBP, ImageFormat.WEBP, "image/webp"));
    }

    @ParameterizedTest
    @MethodSource("supported")
    void detectsFormatFromMagicBytes(byte[] content, ImageFormat format, String mediaType) {
        LogoImage logo = LogoImage.of(content);
        assertThat(logo.format()).isEqualTo(format);
        assertThat(logo.format().mediaType()).isEqualTo(mediaType);
        assertThat(logo.sizeBytes()).isEqualTo(content.length);
    }

    @Test
    void rejectsSvgGifEmptyAndRiffWithoutWebp() {
        byte[] riffWave = Arrays.copyOf(WEBP, WEBP.length);
        riffWave[8] = 'W'; riffWave[9] = 'A'; riffWave[10] = 'V'; riffWave[11] = 'E';
        for (byte[] content : new byte[][] {SVG, GIF, new byte[0], riffWave, bytes(0x89, 'P'), bytes(0xFF, 0xD8)}) {
            assertThatThrownBy(() -> LogoImage.of(content)).isInstanceOf(UnsupportedLogoFormatException.class);
        }
    }

    @Test
    void rejectsMoreThan512Kilobytes() {
        byte[] atLimit = Arrays.copyOf(PNG, LogoImage.MAX_BYTES);
        assertThat(LogoImage.of(atLimit).sizeBytes()).isEqualTo(524_288);
        byte[] tooLarge = Arrays.copyOf(PNG, LogoImage.MAX_BYTES + 1);
        assertThatThrownBy(() -> LogoImage.of(tooLarge)).isInstanceOf(LogoTooLargeException.class)
                .hasMessageContaining("524288");
    }

    @Test
    void etagIsTheQuotedSha256OfTheBytes() throws Exception {
        String sha256 = java.util.HexFormat.of().formatHex(
                java.security.MessageDigest.getInstance("SHA-256").digest(PNG));
        assertThat(LogoImage.of(PNG).etag()).isEqualTo("\"" + sha256 + "\"");
        assertThat(LogoImage.of(PNG).etag()).isNotEqualTo(LogoImage.of(JPEG).etag());
    }

    @Test
    void bytesAreDefensivelyCopied() {
        byte[] content = PNG.clone();
        LogoImage logo = LogoImage.of(content);
        content[0] = 0;
        assertThat(logo.bytes()[0]).isEqualTo((byte) 0x89);
        logo.bytes()[0] = 0;
        assertThat(logo.bytes()[0]).isEqualTo((byte) 0x89);
    }

    @Test
    void etagMatchingHandlesWeakAndListValues() {
        LogoImage logo = LogoImage.of(PNG);
        assertThat(logo.matches(logo.etag())).isTrue();
        assertThat(logo.matches("W/" + logo.etag())).isTrue();
        assertThat(logo.matches("\"other\", " + logo.etag())).isTrue();
        assertThat(logo.matches("*")).isTrue();
        assertThat(logo.matches("\"other\"")).isFalse();
        assertThat(logo.matches(null)).isFalse();
    }

    static byte[] bytes(int... values) {
        byte[] result = new byte[values.length];
        for (int i = 0; i < values.length; i++) {
            result[i] = (byte) values[i];
        }
        return result;
    }
}
