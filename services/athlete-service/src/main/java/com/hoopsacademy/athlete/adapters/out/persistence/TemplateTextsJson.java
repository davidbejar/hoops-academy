package com.hoopsacademy.athlete.adapters.out.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.LocalizedText;
import com.hoopsacademy.athlete.domain.Translations;
import java.util.EnumMap;
import java.util.Map;

/**
 * Reads the {@code i18n} jsonb of templates and their items: language code to texts, the title under {@code titleField}
 * ({@code name} for plans, {@code title} for items). Codes the domain does not support are skipped.
 */
final class TemplateTextsJson {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final TypeReference<Map<String, Map<String, String>>> SHAPE = new TypeReference<>() {};

    private TemplateTextsJson() {}

    static Translations read(String json, String titleField) {
        if (json == null || json.isBlank()) {
            return Translations.NONE;
        }
        Map<ContentLocale, LocalizedText> texts = new EnumMap<>(ContentLocale.class);
        parse(json).forEach((code, fields) -> ContentLocale.fromCode(code).ifPresent(language ->
                texts.put(language, new LocalizedText(fields.get(titleField), fields.get("description")))));
        return Translations.of(texts);
    }

    private static Map<String, Map<String, String>> parse(String json) {
        try {
            return JSON.readValue(json, SHAPE);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Unreadable template texts", e);
        }
    }
}
