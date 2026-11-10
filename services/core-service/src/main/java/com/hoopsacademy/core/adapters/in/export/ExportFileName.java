package com.hoopsacademy.core.adapters.in.export;

import java.text.Normalizer;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * {@code hoops-<academy-slug>-<what>-<yyyyMMdd>.csv} (ADR-0048): each part reduced to lower-case ASCII words joined
 * by {@code -} (accents dropped, anything else a separator, at most 40 characters), a part with nothing left out.
 */
public final class ExportFileName {

    private static final int MAX_PART = 40;
    private static final DateTimeFormatter DAY = DateTimeFormatter.BASIC_ISO_DATE;

    private ExportFileName() {}

    /** @param what the kind of export and its qualifiers, e.g. {@code "roster", "U12 Lions"} */
    public static String csv(String academySlug, LocalDate day, String... what) {
        String parts = Stream.concat(Stream.of("hoops", academySlug), Stream.of(what)).map(ExportFileName::ascii)
                .filter(part -> !part.isEmpty()).collect(Collectors.joining("-"));
        return parts + "-" + DAY.format(day) + ".csv";
    }

    /** Lower-case ASCII letters and digits, runs of anything else as one {@code -}, trimmed, at most 40 characters. */
    public static String ascii(String text) {
        String plain = Normalizer.normalize(text, Normalizer.Form.NFKD).replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "-");
        String trimmed = trimDashes(plain);
        return trimDashes(trimmed.length() > MAX_PART ? trimmed.substring(0, MAX_PART) : trimmed);
    }

    /** {@code Content-Disposition} of a download. */
    public static String attachment(String fileName) {
        return "attachment; filename=\"" + fileName + "\"";
    }

    private static String trimDashes(String text) {
        return text.replaceAll("^-+|-+$", "");
    }
}
