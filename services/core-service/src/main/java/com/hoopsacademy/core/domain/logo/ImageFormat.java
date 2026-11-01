package com.hoopsacademy.core.domain.logo;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Optional;

/** The raster formats accepted for logos, recognised by their magic bytes (never by the declared type). */
public enum ImageFormat {
    PNG("image/png") {
        @Override
        boolean matches(byte[] content) {
            return startsWith(content, 0, new byte[] {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A});
        }
    },
    JPEG("image/jpeg") {
        @Override
        boolean matches(byte[] content) {
            return startsWith(content, 0, new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF});
        }
    },
    WEBP("image/webp") {
        @Override
        boolean matches(byte[] content) {
            return startsWith(content, 0, ascii("RIFF")) && startsWith(content, 8, ascii("WEBP"));
        }
    };

    private final String mediaType;

    ImageFormat(String mediaType) {
        this.mediaType = mediaType;
    }

    public String mediaType() {
        return mediaType;
    }

    abstract boolean matches(byte[] content);

    public static Optional<ImageFormat> detect(byte[] content) {
        return Arrays.stream(values()).filter(format -> format.matches(content)).findFirst();
    }

    private static boolean startsWith(byte[] content, int offset, byte[] signature) {
        if (content.length < offset + signature.length) {
            return false;
        }
        return Arrays.equals(content, offset, offset + signature.length, signature, 0, signature.length);
    }

    private static byte[] ascii(String text) {
        return text.getBytes(StandardCharsets.US_ASCII);
    }
}
