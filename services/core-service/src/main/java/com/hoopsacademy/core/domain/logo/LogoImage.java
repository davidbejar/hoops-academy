package com.hoopsacademy.core.domain.logo;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;

/** A validated academy logo (ADR-0009): PNG/JPEG/WebP by magic bytes, at most 512 KB, strong sha256 ETag. */
public final class LogoImage {

    public static final int MAX_BYTES = 512 * 1024;

    private final ImageFormat format;
    private final byte[] bytes;
    private final String etag;

    private LogoImage(ImageFormat format, byte[] bytes, String etag) {
        this.format = format;
        this.bytes = bytes;
        this.etag = etag;
    }

    /** Validates untrusted upload content. */
    public static LogoImage of(byte[] content) {
        if (content.length > MAX_BYTES) {
            throw new LogoTooLargeException(MAX_BYTES);
        }
        ImageFormat format = ImageFormat.detect(content).orElseThrow(UnsupportedLogoFormatException::new);
        byte[] copy = content.clone();
        return new LogoImage(format, copy, quotedSha256(copy));
    }

    /** Rehydrates a stored logo (already validated on upload). */
    public static LogoImage restore(ImageFormat format, byte[] bytes, String etag) {
        return new LogoImage(format, bytes.clone(), etag);
    }

    public ImageFormat format() {
        return format;
    }

    public byte[] bytes() {
        return bytes.clone();
    }

    public int sizeBytes() {
        return bytes.length;
    }

    public String etag() {
        return etag;
    }

    /** RFC 9110 If-None-Match (weak comparison): {@code *}, a list of tags, or W/ prefixed tags. */
    public boolean matches(String ifNoneMatch) {
        if (ifNoneMatch == null) {
            return false;
        }
        return Arrays.stream(ifNoneMatch.split(","))
                .map(String::strip)
                .map(tag -> tag.startsWith("W/") ? tag.substring(2) : tag)
                .anyMatch(tag -> tag.equals("*") || tag.equals(etag));
    }

    private static String quotedSha256(byte[] content) {
        try {
            return "\"" + HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(content)) + "\"";
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is required by the Java platform", e);
        }
    }
}
