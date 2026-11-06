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
                .isThrownBy(() -> patch("{\"name\": null}").required("name", PatchBody.text(9)));
    }
}
