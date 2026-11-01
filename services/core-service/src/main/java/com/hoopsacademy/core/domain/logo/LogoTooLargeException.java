package com.hoopsacademy.core.domain.logo;

/** The upload exceeds the logo size limit (413). */
public class LogoTooLargeException extends RuntimeException {

    public LogoTooLargeException(int maxBytes) {
        super("A logo may be at most " + maxBytes + " bytes");
    }
}
