package com.hoopsacademy.core.domain.logo;

/** The upload is not a PNG, JPEG or WebP image (415); SVG is rejected on purpose (ADR-0009). */
public class UnsupportedLogoFormatException extends RuntimeException {

    public UnsupportedLogoFormatException() {
        super("The logo must be a PNG, JPEG or WebP image");
    }
}
