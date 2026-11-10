package com.hoopsacademy.core.adapters.in.export;

import com.hoopsacademy.core.domain.shared.AppLocale;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Locale;
import java.util.Optional;

/**
 * The language of an export's labels from {@code Accept-Language} (RFC 9110 §12.5.4): entries by descending quality,
 * header order on ties, {@code q=0} refused; the first of es / en / id wins, anything else is English (ADR-0048, as
 * the athlete templates negotiate it). Never fails.
 */
public final class ExportLanguage {

    public static final AppLocale FALLBACK = AppLocale.EN;

    /** Java's historical code for Indonesian, still produced by some runtimes. */
    private static final String LEGACY_INDONESIAN = "in";

    private record Entry(String tag, double quality) {}

    private ExportLanguage() {}

    public static AppLocale negotiate(String header) {
        if (header == null) {
            return FALLBACK;
        }
        return Arrays.stream(header.split(",")).map(ExportLanguage::entry).filter(e -> e.quality() > 0)
                .sorted(Comparator.comparingDouble(Entry::quality).reversed())
                .map(e -> language(e.tag())).flatMap(Optional::stream).findFirst().orElse(FALLBACK);
    }

    private static Optional<AppLocale> language(String tag) {
        String primary = tag.split("[-_]", 2)[0].toLowerCase(Locale.ROOT);
        String code = LEGACY_INDONESIAN.equals(primary) ? AppLocale.ID.code() : primary;
        return Arrays.stream(AppLocale.values()).filter(locale -> locale.code().equals(code)).findFirst();
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
