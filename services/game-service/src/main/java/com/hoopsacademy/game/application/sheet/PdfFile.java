package com.hoopsacademy.game.application.sheet;

import java.util.Objects;

/** A rendered PDF and the file name it is downloaded under (ADR-0048 pattern, ASCII). */
public record PdfFile(byte[] content, String fileName) {

    public PdfFile {
        content = Objects.requireNonNull(content, "content").clone();
        Objects.requireNonNull(fileName, "fileName");
    }

    @Override
    public byte[] content() {
        return content.clone();
    }
}
