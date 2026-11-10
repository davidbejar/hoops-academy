package com.hoopsacademy.core.adapters.in.export;

import com.hoopsacademy.core.domain.export.ExportLimit;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

/**
 * A CSV file as ADR-0048 specifies it: UTF-8 with BOM, {@code ,} separator, RFC 4180 quoting (a field holding
 * {@code ,}, {@code "}, CR or LF is quoted, a quote doubled), CRLF line ends, one header row, and the formula-injection
 * guard: a text cell starting with {@code =}, {@code +}, {@code -}, {@code @}, TAB or CR gets a leading {@code '}
 * (numbers written as numbers are exempt). At most {@link ExportLimit#MAX_ROWS} rows below the header.
 */
public final class CsvDocument {

    public static final String MEDIA_TYPE = "text/csv; charset=utf-8";

    private static final byte[] BOM = {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
    private static final String SEPARATOR = ",";
    private static final String LINE_END = "\r\n";
    private static final String FORMULA_STARTS = "=+-@\t\r";

    /** One field of a row. */
    public sealed interface Cell permits Text, Number {}

    /** Text; {@code null} is an empty field. */
    public record Text(String value) implements Cell {}

    /** A number written as a number. */
    public record Number(long value) implements Cell {}

    private final StringBuilder content = new StringBuilder();
    private final int columns;
    private int rows;

    public CsvDocument(List<String> header) {
        this.columns = header.size();
        line(header.stream().<Cell>map(Text::new).toList());
    }

    public static Cell text(String value) {
        return new Text(value);
    }

    public static Cell number(long value) {
        return new Number(value);
    }

    /** An ISO {@code yyyy-MM-dd} date, empty when {@code null}. */
    public static Cell date(LocalDate value) {
        return new Text(value == null ? null : value.toString());
    }

    /**
     * Appends a row of exactly one cell per header column.
     *
     * @throws com.hoopsacademy.common.problem.DomainRuleViolation {@code EXPORT_TOO_LARGE} beyond the row limit
     */
    public CsvDocument row(List<Cell> cells) {
        if (cells.size() != columns) {
            throw new IllegalArgumentException("A row needs " + columns + " cells, got " + cells.size());
        }
        ExportLimit.requireWithin(rows + 1L);
        line(cells);
        rows++;
        return this;
    }

    public int rows() {
        return rows;
    }

    /** The file: the BOM, then the UTF-8 text. */
    public byte[] bytes() {
        ByteArrayOutputStream out = new ByteArrayOutputStream(BOM.length + content.length());
        out.writeBytes(BOM);
        out.writeBytes(content.toString().getBytes(StandardCharsets.UTF_8));
        return out.toByteArray();
    }

    private void line(List<Cell> cells) {
        content.append(String.join(SEPARATOR, cells.stream().map(CsvDocument::field).toList())).append(LINE_END);
    }

    private static String field(Cell cell) {
        return switch (cell) {
            case Number number -> Long.toString(number.value());
            case Text text -> quoted(guarded(text.value() == null ? "" : text.value()));
        };
    }

    private static String guarded(String value) {
        return !value.isEmpty() && FORMULA_STARTS.indexOf(value.charAt(0)) >= 0 ? "'" + value : value;
    }

    private static String quoted(String value) {
        boolean needsQuotes = value.contains(SEPARATOR) || value.contains("\"") || value.contains("\r")
                || value.contains("\n");
        return needsQuotes ? "\"" + value.replace("\"", "\"\"") + "\"" : value;
    }
}
