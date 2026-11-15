package com.hoopsacademy.core.adapters.in.export;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.application.export.ExportFormat;
import jakarta.ws.rs.core.MediaType;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * WP116 (ADR-0048 amendment): the roster export answers a PDF only when the caller prefers it; the CSV stays the
 * answer to every other {@code Accept} (absent, {@code *}/{@code *}, {@code text/*}). The list comes sorted by
 * preference from JAX-RS.
 */
class AcceptedFormatTest {

    @Test
    void noPreferenceIsTheCsv() {
        assertThat(AcceptedFormat.of(List.of())).isEqualTo(ExportFormat.CSV);
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
        "*/*                              | CSV",
        "text/csv                         | CSV",
        "text/*                           | CSV",
        "application/pdf                  | PDF",
        "application/*                    | PDF",
        "application/pdf, text/csv        | PDF",
        "text/csv, application/pdf        | CSV",
        "application/json, application/pdf | PDF",
        "image/png, text/csv              | CSV",
        "application/json                 | CSV"})
    void theFirstAcceptedTypeThatIsOneOfTheFormatsWins(String accept, ExportFormat expected) {
        List<MediaType> acceptable = Arrays.stream(accept.split(",")).map(String::trim).map(MediaType::valueOf)
                .toList();

        assertThat(AcceptedFormat.of(acceptable)).isEqualTo(expected);
    }

    @Test
    void eachFormatNamesItselfInLowerCaseForTheAuditRow() {
        assertThat(ExportFormat.CSV.code()).isEqualTo("csv");
        assertThat(ExportFormat.PDF.code()).isEqualTo("pdf");
    }
}
