package com.hoopsacademy.common.problem;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

/** Which request text PostgreSQL (and the rest of the stack) cannot take: SD-02 of the 2026-11 review. */
class UnsafeTextTest {

    @ParameterizedTest
    @ValueSource(strings = {"/platform/tenants?q=%00", "/a?q=%1f", "/a?q=%1F", "/a?q=%7f", "/a?q=%7F", "/a?q=%09",
        "/a?q=%0A", "/a?q=%0d", "/a/b%00c", "/a?x=1&q=ab%01", "/a?q=\u0001", "/a?q=\u001f", "/a?q=\u007f", "%00",
        "/a?q=%19", "/a?q=%1a", "/a?q=%1A", "/a?q=%0b", "/a?q=%0B", "%1e"})
    void aControlCharacterInTheUriIsUnsafe(String rawUri) {
        assertThat(UnsafeText.uriHasControlCharacter(rawUri)).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {"/a?q=abc", "/a?q=%20b", "/a?q=%2500", "/a?q=%25%30%30", "/a?q=%", "/a?q=%0", "/a?q=%0G",
        "/a?q=%G0", "/a?q=%80", "/a?q=%C2%80", "/a?q=%E2%80%8B", "/a?q=caf%C3%A9", "/a?q=+", "/a?q=%2F%3F", "/a?q=%20",
        "/a?q=%8f", "/a?q=%6F", "/a?q=%7E", "/a?q=%2f", "/a?q= ", "/a?q=\u0080", "/a?q=~", "/a?q=%/0", "/a?q=%:0",
        "/a?q=%`0", "/a?q=%@0", "/a?q=%g0", "/a?q=%1g", "/a?q=%1G", "/a?q=%1:", "/a?q=%1@", "/a?q=%1`",
        "/a?q=%٠٠"})
    void printableAndNonAsciiTextIsSafe(String rawUri) {
        assertThat(UnsafeText.uriHasControlCharacter(rawUri)).isFalse();
    }

    @ParameterizedTest
    @NullAndEmptySource
    void noUriIsSafe(String rawUri) {
        assertThat(UnsafeText.uriHasControlCharacter(rawUri)).isFalse();
    }

    @ParameterizedTest
    @ValueSource(strings = {"\u0000", "a\u0000", "\u0000b", "a\u0000b"})
    void aNulCharacterInBodyTextIsUnsafe(String text) {
        assertThat(UnsafeText.containsNul(text)).isTrue();
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"plain", "line\nbreak\ttab\r", "\u0001\u001f\u007f", "0", "\\u0000", "café"})
    void anyOtherBodyTextIsStorable(String text) {
        assertThat(UnsafeText.containsNul(text)).isFalse();
    }

    @Test
    void theFirstNulInAJsonTreeIsFoundWithItsPath() throws Exception {
        assertThat(UnsafeText.nulPathIn(json("\"a\\u0000\""))).contains(List.of());
        assertThat(UnsafeText.nulPathIn(json("{\"name\":\"ok\",\"note\":\"\\u0000\"}"))).contains(List.of("note"));
        assertThat(UnsafeText.nulPathIn(json("[\"ok\",\"x\\u0000\"]"))).contains(List.of(1));
        assertThat(UnsafeText.nulPathIn(json("{\"items\":[{\"x\":\"ok\"},{\"x\":\"\\u0000\",\"y\":\"\\u0000\"}]}")))
                .contains(List.of("items", 1, "x"));
    }

    @Test
    void aNulInAFieldNameIsFoundAtTheObjectHoldingIt() throws Exception {
        assertThat(UnsafeText.nulPathIn(json("{\"a\\u0000\":1}"))).contains(List.of());
        assertThat(UnsafeText.nulPathIn(json("{\"outer\":{\"ok\":1,\"\\u0000\":2}}"))).contains(List.of("outer"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"{}", "[]", "null", "1", "true", "\"plain\"", "{\"a\":\"line\\nbreak\\u0001\",\"b\":[1,\"x\",null]}",
        "[[[\"deep\"]]]", "{\"\\\\u0000\":\"\\\\u0000\"}"})
    void aTreeWithoutNulHasNoPath(String text) throws Exception {
        assertThat(UnsafeText.nulPathIn(json(text))).isEmpty();
    }

    private static JsonNode json(String text) throws Exception {
        return new ObjectMapper().readTree(text);
    }
}
