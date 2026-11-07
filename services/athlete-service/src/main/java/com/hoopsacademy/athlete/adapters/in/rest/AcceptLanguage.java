package com.hoopsacademy.athlete.adapters.in.rest;

import com.hoopsacademy.athlete.domain.ContentLocale;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Reads an {@code Accept-Language} header (RFC 9110 §12.5.4) into the template language: entries by descending
 * quality, header order on ties, {@code q=0} refused. Never fails: anything unusable falls back to English.
 */
final class AcceptLanguage {

    private record Entry(String tag, double quality) {}

    private AcceptLanguage() {}

    static ContentLocale negotiate(String header) {
        if (header == null) {
            return ContentLocale.FALLBACK;
        }
        List<String> preferred = Arrays.stream(header.split(",")).map(AcceptLanguage::entry)
                .filter(e -> e.quality() > 0).sorted(Comparator.comparingDouble(Entry::quality).reversed())
                .map(Entry::tag).toList();
        return ContentLocale.negotiate(preferred);
    }

    /** An entry without a tag (e.g. {@code ";q=1"}) keeps an empty tag, which names no language. */
    private static Entry entry(String raw) {
        String[] parts = raw.split(";", -1);
        String tag = parts[0].trim();
        double quality = 1;
        for (int i = 1; i < parts.length; i++) {
            String parameter = parts[i].trim().toLowerCase(Locale.ROOT);
            if (parameter.startsWith("q=")) {
                quality = parseQuality(parameter.substring(2));
            }
        }
        return new Entry(tag, quality);
    }

    private static double parseQuality(String value) {
        try {
            return Double.parseDouble(value.trim());
        } catch (NumberFormatException e) {
            return 1;
        }
    }
}
