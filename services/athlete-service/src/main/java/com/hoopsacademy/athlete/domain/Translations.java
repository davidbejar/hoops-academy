package com.hoopsacademy.athlete.domain;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/** The texts of a global template (or of one of its items) in languages other than its own. */
public record Translations(Map<ContentLocale, LocalizedText> texts) {

    public static final Translations NONE = new Translations(Map.of());

    public Translations {
        texts = Map.copyOf(texts);
    }

    public static Translations of(Map<ContentLocale, LocalizedText> texts) {
        return texts == null ? NONE : new Translations(texts);
    }

    public Optional<LocalizedText> in(ContentLocale language) {
        return Optional.ofNullable(texts.get(language));
    }

    public boolean isEmpty() {
        return texts.isEmpty();
    }

    /** A text and the language it is written in. */
    public record Choice(String language, LocalizedText text) {}

    /**
     * The text to show for {@code requested}: tried for the requested language, then for {@link ContentLocale#FALLBACK};
     * each try takes the own text when it is the own language, else the translation. Nothing found: the own text.
     */
    public Choice choose(ContentLocale requested, String ownLanguage, LocalizedText own) {
        for (ContentLocale candidate : List.of(requested, ContentLocale.FALLBACK)) {
            if (candidate.code().equals(ownLanguage)) {
                return new Choice(ownLanguage, own);
            }
            Optional<LocalizedText> translated = in(candidate);
            if (translated.isPresent()) {
                return new Choice(candidate.code(), translated.get());
            }
        }
        return new Choice(ownLanguage, own);
    }
}
