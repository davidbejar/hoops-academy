package com.hoopsacademy.core.adapters.in.export;

import static com.hoopsacademy.core.adapters.in.export.CsvDocument.number;
import static com.hoopsacademy.core.adapters.in.export.CsvDocument.text;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

/** ADR-0048: UTF-8 with BOM, {@code ,}, RFC 4180 quoting, CRLF, one header row, the formula guard, 10,000 rows. */
class CsvDocumentTest {

    @Test
    void aFileStartsWithTheBomAndEndsEveryLineWithCrlf() {
        byte[] bytes = new CsvDocument(List.of("Name", "Shirt")).row(List.of(text("Uma"), text("7"))).bytes();

        assertThat(Arrays.copyOf(bytes, 3)).containsExactly(0xEF, 0xBB, 0xBF);
        assertThat(body(bytes)).isEqualTo("Name,Shirt\r\nUma,7\r\n");
        assertThat(CsvDocument.MEDIA_TYPE).isEqualTo("text/csv; charset=utf-8");
    }

    @Test
    void anEmptyDocumentHasTheHeaderOnly() {
        assertThat(body(new CsvDocument(List.of("A", "B")).bytes())).isEqualTo("A,B\r\n");
        assertThat(new CsvDocument(List.of("A")).rows()).isZero();
    }

    @Test
    void fieldsWithASeparatorAQuoteOrALineBreakAreQuotedAndQuotesDoubled() {
        String line = csv(text("a,b"), text("say \"hi\""), text("two\nlines"), text("cr\rhere"), text("plain"));

        assertThat(line).isEqualTo("\"a,b\",\"say \"\"hi\"\"\",\"two\nlines\",\"cr\rhere\",plain\r\n");
    }

    @Test
    void textThatAFormulaCouldStartWithGetsALeadingApostrophe() {
        assertThat(csv(text("=SUM(A1)"), text("+34 600"), text("-3"), text("@cmd"), text("\tx"), text("\rx")))
                .isEqualTo("'=SUM(A1),'+34 600,'-3,'@cmd,'\tx,\"'\rx\"\r\n");
        assertThat(csv(text("a=b"), text("x-1"), text("'quoted"), text(" =x"))).isEqualTo("a=b,x-1,'quoted, =x\r\n");
    }

    @Test
    void numbersAreWrittenAsNumbersWithoutTheGuard() {
        assertThat(csv(number(-3), number(0), number(12))).isEqualTo("-3,0,12\r\n");
    }

    @Test
    void missingValuesAreEmptyFieldsAndDatesAreIso() {
        assertThat(csv(text(null), CsvDocument.date(null), CsvDocument.date(LocalDate.of(2026, 3, 9)), text("")))
                .isEqualTo(",,2026-03-09,\r\n");
    }

    @Test
    void theHeaderIsGuardedAndQuotedLikeText() {
        assertThat(body(new CsvDocument(List.of("=x", "a,b")).bytes())).isEqualTo("'=x,\"a,b\"\r\n");
    }

    @Test
    void textIsEncodedAsUtf8() {
        byte[] bytes = new CsvDocument(List.of("Año")).row(List.of(text("Núñez"))).bytes();

        assertThat(new String(bytes, StandardCharsets.UTF_8)).isEqualTo("﻿Año\r\nNúñez\r\n");
    }

    @Test
    void tenThousandRowsAreWrittenAndOneMoreIsRefused() {
        CsvDocument document = new CsvDocument(List.of("N"));
        for (int i = 0; i < 10_000; i++) {
            document.row(List.of(number(i)));
        }

        assertThat(document.rows()).isEqualTo(10_000);
        assertThatThrownBy(() -> document.row(List.of(number(10_000)))).isInstanceOf(DomainRuleViolation.class)
                .extracting("code").isEqualTo("EXPORT_TOO_LARGE");
        assertThat(document.rows()).isEqualTo(10_000);
    }

    @Test
    void aRowMustHaveOneCellPerColumn() {
        CsvDocument document = new CsvDocument(List.of("A", "B"));

        assertThatThrownBy(() -> document.row(List.of(text("only one")))).isInstanceOf(IllegalArgumentException.class);
    }

    private static String csv(CsvDocument.Cell... cells) {
        List<String> header = Arrays.stream(cells).map(cell -> "h").toList();
        String all = body(new CsvDocument(header).row(List.of(cells)).bytes());
        return all.substring(all.indexOf("\r\n") + 2);
    }

    private static String body(byte[] bytes) {
        return new String(bytes, 3, bytes.length - 3, StandardCharsets.UTF_8);
    }
}
