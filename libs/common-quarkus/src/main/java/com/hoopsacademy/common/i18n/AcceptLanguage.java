package com.hoopsacademy.common.i18n;

import java.util.Arrays;
import java.util.Comparator;
import java.util.Locale;
import java.util.Optional;

/**
 * The language of an answer from {@code Accept-Language} (RFC 9110 §12.5.4): entries by descending quality, header
 * order on ties, {@code q=0} refused, an unreadable quality counts as 1; the first of es / en / id wins, anything else
 * is English (ADR-0048). Never fails. One parser for core's exports, game's match sheet and athlete's templates (X-07).
 */
public final class AcceptLanguage {

    private record Entry(String tag, double quality) {}

    private AcceptLanguage() {}

    public static AppLanguage negotiate(String header) {
        if (header == null) {
            return AppLanguage.FALLBACK;
        }
        return Arrays.stream(header.split(",")).map(AcceptLanguage::entry).filter(entry -> entry.quality() > 0)
                .sorted(Comparator.comparingDouble(Entry::quality).reversed())
                .map(entry -> AppLanguage.fromTag(entry.tag())).flatMap(Optional::stream).findFirst()
                .orElse(AppLanguage.FALLBACK);
    }

    /** An entry without a tag (e.g. {@code ";q=1"}) keeps an empty tag, which names no language. */
    private static Entry entry(String raw) {
        String[] parts = raw.split(";", -1);
        double quality = 1;
        for (int i = 1; i < parts.length; i++) {
            String parameter = parts[i].trim().toLowerCase(Locale.ROOT);
            if (parameter.startsWith("q=")) {
                quality = parseQuality(parameter.substring(2));
            }
        }
        return new Entry(parts[0].trim(), quality);
    }

    private static double parseQuality(String value) {
        try {
            return Double.parseDouble(value.trim());
        } catch (NumberFormatException e) {
            return 1;
        }
    }
}
