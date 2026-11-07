package com.hoopsacademy.athlete.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatExceptionOfType;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.athlete.application.InvalidRequestException;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** ADR-0032: absent or null = unchanged, named in {@code clear} = set to null, both a value and {@code clear} = 400. */
class PatchBodyTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final Set<String> CLEARABLE = Set.of("location", "notes");

    private static PatchBody patch(String json) {
        return new PatchBody(read(json), CLEARABLE);
    }

    private static JsonNode read(String json) {
        try {
            return JSON.readTree(json);
        } catch (Exception e) {
            throw new IllegalArgumentException(e);
        }
    }

    @Test
    void anAbsentNullableFieldIsUnchanged() {
        assertThat(patch("{\"notes\": \"x\"}").nullable("location", PatchBody.text(200))).isEmpty();
    }

    @Test
    void anExplicitNullIsUnchangedToo() {
        assertThat(patch("{\"location\": null, \"notes\": \"x\"}").nullable("location", PatchBody.text(200))).isEmpty();
    }

    @Test
    void aValueIsAChange() {
        assertThat(patch("{\"location\": \"Court 1\"}").nullable("location", PatchBody.text(200)))
                .contains(Optional.of("Court 1"));
    }

    @Test
    void aFieldNamedInClearIsSetToNull() {
        PatchBody patch = patch("{\"clear\": [\"location\"]}");

        assertThat(patch.nullable("location", PatchBody.text(200))).contains(Optional.empty());
        assertThat(patch.nullable("notes", PatchBody.text(200))).isEmpty();
    }

    @Test
    void aNullValueNextToClearIsNoContradiction() {
        assertThat(patch("{\"location\": null, \"clear\": [\"location\"]}").nullable("location", PatchBody.text(200)))
                .contains(Optional.empty());
    }

    @Test
    void aValueForAFieldNamedInClearIsAContradiction() {
        assertThatExceptionOfType(InvalidRequestException.class)
                .isThrownBy(() -> patch("{\"location\": \"Court 1\", \"clear\": [\"location\"]}"))
                .satisfies(e -> {
                    assertThat(e.field()).isEqualTo("location");
                    assertThat(e.code()).isEqualTo("CLEAR_CONFLICT");
                });
    }

    @ParameterizedTest
    @ValueSource(strings = {"{\"clear\": [\"startsAt\"]}", "{\"clear\": [\"plan\"]}", "{\"clear\": [1]}",
            "{\"clear\": \"location\"}", "{\"clear\": [\"notes\", \"notes\"]}"})
    void anUnknownMalformedOrRepeatedClearListIsRejected(String json) {
        assertThatExceptionOfType(InvalidRequestException.class).isThrownBy(() -> patch(json))
                .satisfies(e -> {
                    assertThat(e.field()).isEqualTo("clear");
                    assertThat(e.code()).isEqualTo("INVALID_VALUE");
                });
    }

    @ParameterizedTest
    @ValueSource(strings = {"{}", "{\"clear\": []}", "{\"clear\": null}", "[]"})
    void aBodyThatChangesNothingIsAnEmptyPatch(String json) {
        assertThatExceptionOfType(InvalidRequestException.class).isThrownBy(() -> patch(json))
                .satisfies(e -> assertThat(e.code()).isEqualTo("EMPTY_PATCH"));
    }

    @Test
    void aMissingBodyIsAnEmptyPatch() {
        assertThatExceptionOfType(InvalidRequestException.class).isThrownBy(() -> new PatchBody(null, CLEARABLE))
                .satisfies(e -> assertThat(e.code()).isEqualTo("EMPTY_PATCH"));
    }

    @Test
    void anEmptyClearNextToAValueIsFine() {
        assertThat(patch("{\"notes\": \"x\", \"clear\": []}").nullable("notes", PatchBody.text(200)))
                .contains(Optional.of("x"));
    }

    @Test
    void readingANullableFieldThatIsNotDeclaredClearableIsAProgrammingError() {
        assertThatIllegalStateException().isThrownBy(() -> patch("{\"notes\": \"x\"}").nullable("other", PatchBody.text(9)));
    }

    @Test
    void aRequiredFieldIsNeverClearedAndRejectsNull() {
        assertThat(patch("{\"notes\": \"x\"}").required("name", PatchBody.text(9))).isEmpty();
        assertThatExceptionOfType(InvalidRequestException.class)
                .isThrownBy(() -> patch("{\"name\": null}").required("name", PatchBody.text(9)))
                .withMessage("name must not be null");
    }

    @Test
    void aRequiredValueIsTakenAndAnInvalidOneNamesTheField() {
        assertThat(patch("{\"name\": \"Ana\"}").required("name", PatchBody.text(9))).contains("Ana");
        assertThatExceptionOfType(InvalidRequestException.class)
                .isThrownBy(() -> patch("{\"name\": 3}").required("name", PatchBody.text(9)))
                .satisfies(e -> {
                    assertThat(e.field()).isEqualTo("name");
                    assertThat(e.code()).isEqualTo("INVALID_VALUE");
                    assertThat(e.getMessage()).isEqualTo("name must be a string of at most 9 characters");
                });
    }

    @Test
    void aClearNameOutsideTheClearableOnesNamesTheAllowedOnes() {
        assertThatExceptionOfType(InvalidRequestException.class).isThrownBy(() -> patch("{\"clear\": [\"plan\"]}"))
                .withMessage("clear may only name location, notes");
        assertThatExceptionOfType(InvalidRequestException.class)
                .isThrownBy(() -> new PatchBody(read("{\"clear\": [1]}"), Set.of("1")))
                .as("names are strings").satisfies(e -> assertThat(e.field()).isEqualTo("clear"));
    }

    @Test
    void textIsTakenUpToItsMaximumLength() {
        assertThat((String) value("\"abc\"", PatchBody.text(3))).isEqualTo("abc");
        assertThat((String) value("\" \"", PatchBody.text(3))).as("may be blank").isEqualTo(" ");
        assertThat((String) value("\"abc\"", PatchBody.nonBlankText(3))).isEqualTo("abc");
        assertThat((Integer) value("2", PatchBody.integer(2, 4))).isEqualTo(2);
        assertThat((Integer) value("4", PatchBody.integer(2, 4))).isEqualTo(4);
        assertThat((java.math.BigDecimal) value("1.5", PatchBody.decimal(1.5, 2.5))).isEqualByComparingTo("1.5");
        assertThat((java.math.BigDecimal) value("2.5", PatchBody.decimal(1.5, 2.5))).isEqualByComparingTo("2.5");
        assertThat((java.math.BigDecimal) value("2", PatchBody.decimal(1.5, 2.5))).isEqualByComparingTo("2");
        assertThat((java.time.LocalDate) value("\"2026-11-07\"", PatchBody.fromText(java.time.LocalDate::parse, "a date")))
                .isEqualTo(java.time.LocalDate.of(2026, 11, 7));
    }

    @ParameterizedTest
    @ValueSource(strings = {"\"abcd\"", "3", "true"})
    void textTooLongOrNotAStringIsInvalid(String json) {
        assertInvalid(json, PatchBody.text(3), "a string of at most 3 characters");
    }

    @ParameterizedTest
    @ValueSource(strings = {"\"abcd\"", "\"  \"", "3"})
    void nonBlankTextTooLongBlankOrNotAStringIsInvalid(String json) {
        assertInvalid(json, PatchBody.nonBlankText(3), "a non-blank string of at most 3 characters");
    }

    @ParameterizedTest
    @ValueSource(strings = {"1", "5", "\"3\"", "3.5"})
    void anIntegerOutsideItsRangeOrNotAnIntegerIsInvalid(String json) {
        assertInvalid(json, PatchBody.integer(2, 4), "an integer between 2 and 4");
    }

    @ParameterizedTest
    @ValueSource(strings = {"1.49", "2.51", "\"2\""})
    void aNumberOutsideItsRangeOrNotANumberIsInvalid(String json) {
        assertInvalid(json, PatchBody.decimal(1.5, 2.5), "a number between 1.5 and 2.5");
    }

    @Test
    void aTextMemberMustBeAStringEvenWhenItsParserWouldTakeANumber() {
        assertInvalid("7", PatchBody.fromText(Integer::valueOf, "a number as text"), "a number as text");
        assertThat((Integer) value("\"7\"", PatchBody.fromText(Integer::valueOf, "a number as text"))).isEqualTo(7);
    }

    @ParameterizedTest
    @ValueSource(strings = {"20261107", "\"7 Nov\""})
    void aTextThatDoesNotParseIsInvalid(String json) {
        assertInvalid(json, PatchBody.fromText(java.time.LocalDate::parse, "a date"), "a date");
    }

    private static <T> T value(String json, java.util.function.Function<JsonNode, T> parser) {
        return patch("{\"v\": " + json + "}").required("v", parser).orElseThrow();
    }

    private static void assertInvalid(String json, java.util.function.Function<JsonNode, ?> parser, String expected) {
        assertThatExceptionOfType(InvalidRequestException.class)
                .isThrownBy(() -> patch("{\"v\": " + json + "}").required("v", parser))
                .withMessage("v must be " + expected);
    }
}
