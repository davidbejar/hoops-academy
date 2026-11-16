package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.sheet.SheetLanguage;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Locale;
import java.util.Optional;

/**
 * The match sheet's language from {@code Accept-Language} (RFC 9110 §12.5.4): entries by descending quality, header
 * order on ties, {@code q=0} refused; the first of es / en / id wins ({@code in}, Java's old code, is Indonesian),
 * anything else is English (ADR-0048, as core's exports and athlete's templates negotiate it). Never fails.
 */
final class AcceptLanguage {

    private static final String LEGACY_INDONESIAN = "in";

    private record Entry(String tag, double quality) {}

    private AcceptLanguage() {}

    static SheetLanguage negotiate(String header) {
        if (header == null) {
            return SheetLanguage.FALLBACK;
        }
        return Arrays.stream(header.split(",")).map(AcceptLanguage::entry).filter(e -> e.quality() > 0)
                .sorted(Comparator.comparingDouble(Entry::quality).reversed())
                .map(e -> language(e.tag())).flatMap(Optional::stream).findFirst().orElse(SheetLanguage.FALLBACK);
    }

    private static Optional<SheetLanguage> language(String tag) {
        String primary = tag.split("[-_]", 2)[0].toLowerCase(Locale.ROOT);
        String code = LEGACY_INDONESIAN.equals(primary) ? SheetLanguage.ID.code() : primary;
        return Arrays.stream(SheetLanguage.values()).filter(language -> language.code().equals(code)).findFirst();
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
