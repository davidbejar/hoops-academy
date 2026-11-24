package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** What core and game accept from pdf-service as a sheet (X-06): a body that starts with the PDF magic. */
class PdfServiceClientsTest {

    @ParameterizedTest
    @ValueSource(strings = {"%PDF-", "%PDF-1.7\n%âãÏÓ"})
    void aBodyThatStartsWithThePdfMagicIsAPdf(String body) {
        assertThat(PdfServiceClients.isPdf(body.getBytes(StandardCharsets.ISO_8859_1))).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "%PDF", "%pdf-1.7", " %PDF-1.7", "<html>%PDF-</html>", "{\"type\":\"urn\"}"})
    void anythingElseIsNot(String body) {
        assertThat(PdfServiceClients.isPdf(body.getBytes(StandardCharsets.ISO_8859_1))).isFalse();
    }

    @Test
    void noBodyIsNoPdf() {
        assertThat(PdfServiceClients.isPdf(null)).isFalse();
    }
}
