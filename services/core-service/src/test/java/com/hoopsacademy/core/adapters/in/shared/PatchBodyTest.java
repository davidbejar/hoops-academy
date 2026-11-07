package com.hoopsacademy.core.adapters.in.shared;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * ADR-0032: absent or null = unchanged, named in {@code clear} = set to null, both a value and {@code clear} = 400. A
 * field is nullable exactly when the request declares it clearable; {@code null} for any other field is a 400.
 */
class PatchBodyTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final Set<String> CLEARABLE = Set.of("email", "phone", "birthDate", "gender");

    @Test
    void anAbsentOrNullFieldIsUnchangedAndAValueIsAChange() {
        PatchBody patch = patch("{\"phone\":null,\"givenName\":\"Ana\",\"birthDate\":\"2010-02-28\"}");
        Patch<String> phone = patch.text("phone", 32);
        Patch<String> email = patch.email("email");
        Patch<String> given = patch.nonBlankText("givenName", 80);
        Patch<LocalDate> birth = patch.parsed("birthDate", LocalDate::parse);
        patch.validate();

        assertThat(phone.isPresent()).as("null is unchanged").isFalse();
        assertThat(email.isPresent()).isFalse();
        assertThat(given.applyTo("x")).isEqualTo("Ana");
        assertThat(birth.applyTo(null)).isEqualTo(LocalDate.of(2010, 2, 28));
    }

    @Test
    void aFieldNamedInClearIsSetToNull() {
        PatchBody patch = patch("{\"clear\":[\"phone\",\"gender\"]}");
        Patch<String> phone = patch.text("phone", 32);
        Patch<Gender> gender = patch.parsed("gender", Gender::valueOf);
        Patch<String> email = patch.email("email");
        patch.validate();

        assertThat(phone.clears()).isTrue();
        assertThat(gender.clears()).isTrue();
        assertThat(email.isPresent()).isFalse();
    }

    @Test
    void aNullValueNextToClearIsNoContradiction() {
        PatchBody patch = patch("{\"phone\":null,\"clear\":[\"phone\"]}");
        Patch<String> phone = patch.text("phone", 32);
        patch.validate();

        assertThat(phone.clears()).isTrue();
    }

    @Test
    void aValueForAFieldNamedInClearIsAContradiction() {
        PatchBody patch = patch("{\"phone\":\"1\",\"clear\":[\"phone\"]}");
        patch.text("phone", 32);

        assertThatThrownBy(patch::validate).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).containsExactly(
                        new Problem.Violation("phone", "CLEAR_CONFLICT", "phone is both given a value and named in clear")));
    }

    @ParameterizedTest
    @ValueSource(strings = {"{\"clear\":[\"givenName\"]}", "{\"clear\":[\"fone\"]}", "{\"clear\":[1]}",
            "{\"clear\":\"phone\"}", "{\"clear\":[\"phone\",\"phone\"]}"})
    void anUnknownMalformedOrRepeatedClearListIsRejected(String json) {
        assertThatThrownBy(() -> patch(json).validate()).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).singleElement().satisfies(v -> {
                    assertThat(v.field()).isEqualTo("clear");
                    assertThat(v.code()).isEqualTo("INVALID_VALUE");
                }));
    }

    @Test
    void aRequestWithNothingClearableRejectsAnyClearName() {
        assertThatThrownBy(() -> PatchBody.of(json("{\"clear\":[\"name\"]}")).validate())
                .isInstanceOfSatisfying(InvalidRequestException.class,
                        e -> assertThat(e.violations()).extracting(Problem.Violation::field).containsExactly("clear"));
    }

    @Test
    void nullForAFieldThatCannotBeClearedIsAViolation() {
        PatchBody patch = patch("{\"givenName\":null}");
        patch.nonBlankText("givenName", 80);

        assertThatThrownBy(patch::validate).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).extracting(Problem.Violation::field).containsExactly("givenName"));
    }

    @Test
    void collectsEveryViolation() {
        PatchBody patch = patch(
                "{\"givenName\":null,\"phone\":\"" + "9".repeat(33) + "\",\"email\":\"nope\",\"birthDate\":3,"
                        + "\"gender\":\"X\",\"code\":\"a b\",\"rank\":-1}");
        patch.nonBlankText("givenName", 80);
        patch.text("phone", 32);
        patch.email("email");
        patch.parsed("birthDate", LocalDate::parse);
        patch.parsed("gender", Gender::valueOf);
        patch.matching("code", Pattern.compile("^[A-Z]+$"));
        patch.integer("rank", 0, 10);

        assertThatThrownBy(patch::validate).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).extracting(Problem.Violation::field)
                        .containsExactly("givenName", "phone", "email", "birthDate", "gender", "code", "rank"));
    }

    @Test
    void propertiesOutsideTheAllowedSetAreViolations() {
        PatchBody patch = PatchBody.of(json("{\"givenName\":\"Ana\",\"phone\":\"1\",\"roles\":[]}"));
        patch.nonBlankText("givenName", 80);
        patch.allowOnly("givenName", "familyName", "email");

        assertThatThrownBy(patch::validate).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).extracting(Problem.Violation::field).containsExactly("phone", "roles"));
    }

    @Test
    void anEmptyBodyOrAnEmptyClearAloneIsAnEmptyPatch() {
        assertThatThrownBy(() -> patch("{}").validate()).isInstanceOf(InvalidRequestException.class);
        assertThatThrownBy(() -> patch("{\"clear\":[]}").validate()).isInstanceOf(InvalidRequestException.class);
        assertThatThrownBy(() -> patch("[1]")).isInstanceOf(InvalidRequestException.class);
        assertThatThrownBy(() -> PatchBody.of(null, CLEARABLE)).isInstanceOf(InvalidRequestException.class);
        patch("{\"clear\":[\"phone\"]}").validate();
        patch("{\"phone\":null}").validate();
    }

    @Test
    void domainRuleViolationsOfParsersPropagate() {
        PatchBody patch = PatchBody.of(json("{\"timezone\":\"Mars/Olympus\"}"));
        assertThatThrownBy(() -> patch.parsed("timezone", Constraints::zone)).isInstanceOf(DomainRuleViolation.class);
        assertThat(Constraints.zone("Asia/Jakarta").getId()).isEqualTo("Asia/Jakarta");
        assertThat(InvalidRequestException.of("f", "m").violations()).hasSize(1);
    }

    @Test
    void aNullClearListClearsNothing() {
        PatchBody patch = patch("{\"clear\":null,\"phone\":\"1\"}");
        Patch<String> phone = patch.text("phone", 32);
        patch.validate();

        assertThat(phone.applyTo(null)).isEqualTo("1");
    }

    @Test
    void aClearNameOutsideTheClearableOnesNamesTheAllowedOnes() {
        assertThat(violationsOf(patch("{\"clear\":[\"fone\"]}"))).extracting(Problem.Violation::message)
                .containsExactly("clear may only name birthDate, email, gender, phone");
        assertThat(violationsOf(PatchBody.of(json("{\"clear\":[\"name\"]}")))).extracting(Problem.Violation::message)
                .containsExactly("clear this request has nothing to clear");
    }

    @Test
    void aClearListNamesPropertiesByStringOnly() {
        PatchBody patch = PatchBody.of(json("{\"clear\":[1]}"), Set.of("1"));

        assertThat(violationsOf(patch)).extracting(Problem.Violation::field).containsExactly("clear");
    }

    @Test
    void textsAreTakenUpToTheirMaximumLength() {
        PatchBody patch = patch("{\"a\":\"" + "x".repeat(5) + "\",\"b\":\" \",\"c\":\"" + "y".repeat(5) + "\"}");
        Patch<String> a = patch.text("a", 5);
        Patch<String> b = patch.text("b", 5);
        Patch<String> c = patch.nonBlankText("c", 5);
        patch.validate();

        assertThat(a.applyTo(null)).isEqualTo("xxxxx");
        assertThat(b.applyTo(null)).as("text may be blank").isEqualTo(" ");
        assertThat(c.applyTo(null)).isEqualTo("yyyyy");
    }

    @Test
    void aTextTooLongBlankOrNotAStringIsAViolation() {
        PatchBody patch = patch("{\"a\":\"xxxxxx\",\"b\":5,\"c\":\"yyyyyy\",\"d\":\"  \",\"e\":true}");
        Patch<String> a = patch.text("a", 5);
        patch.text("b", 5);
        patch.nonBlankText("c", 5);
        patch.nonBlankText("d", 5);
        patch.nonBlankText("e", 5);

        assertThat(a.isPresent()).isFalse();
        assertThat(violationsOf(patch)).extracting(Problem.Violation::field).containsExactly("a", "b", "c", "d", "e");
    }

    @Test
    void integersAreTakenWithinTheirInclusiveRange() {
        PatchBody patch = patch("{\"low\":1,\"high\":8}");
        Patch<Integer> low = patch.integer("low", 1, 8);
        Patch<Integer> high = patch.integer("high", 1, 8);
        patch.validate();

        assertThat(low.applyTo(null)).isEqualTo(1);
        assertThat(high.applyTo(null)).isEqualTo(8);
    }

    @Test
    void anIntegerOutsideItsRangeOrNotAnIntegerIsAViolation() {
        PatchBody patch = patch("{\"low\":0,\"high\":9,\"text\":\"3\",\"real\":3.5}");
        Patch<Integer> low = patch.integer("low", 1, 8);
        patch.integer("high", 1, 8);
        patch.integer("text", 1, 8);
        patch.integer("real", 1, 8);

        assertThat(low.isPresent()).isFalse();
        assertThat(violationsOf(patch)).extracting(Problem.Violation::field)
                .containsExactly("low", "high", "text", "real");
    }

    @Test
    void anEmailIsTakenUpTo254Characters() {
        String longest = "a".repeat(242) + "@example.org";
        PatchBody patch = patch("{\"email\":\"" + longest + "\"}");
        Patch<String> email = patch.email("email");
        patch.validate();

        assertThat(longest).hasSize(254);
        assertThat(email.applyTo(null)).isEqualTo(longest);
    }

    @Test
    void anEmailTooLongMalformedOrNotAStringIsAViolation() {
        PatchBody patch = patch("{\"email\":\"" + "a".repeat(243) + "@example.org\",\"phone\":\"a@b\",\"x\":1,"
                + "\"y\":{\"a\":\"b@c.de\"},\"z\":[\"b@c.de\"]}");
        Patch<String> email = patch.email("email");
        patch.email("phone");
        patch.email("x");
        patch.email("y");
        patch.email("z");

        assertThat(email.isPresent()).isFalse();
        assertThat(violationsOf(patch)).extracting(Problem.Violation::field).containsExactly("email", "phone", "x", "y", "z");
    }

    @Test
    void aMatchingTextIsTakenAndAnyOtherValueIsAViolation() {
        PatchBody patch = patch("{\"code\":\"ABC\",\"bad\":\"abc\",\"num\":1}");
        Patch<String> code = patch.matching("code", Pattern.compile("^[A-Z]+$"));
        Patch<String> bad = patch.matching("bad", Pattern.compile("^[A-Z]+$"));
        patch.matching("num", Pattern.compile("^[0-9]+$"));

        assertThat(code.applyTo(null)).isEqualTo("ABC");
        assertThat(bad.isPresent()).isFalse();
        assertThat(violationsOf(patch)).extracting(Problem.Violation::field).containsExactly("bad", "num");
    }

    @Test
    void aParsedMemberMustBeAStringThatParses() {
        PatchBody patch = patch("{\"birthDate\":20100228,\"gender\":\"X\"}");
        Patch<LocalDate> birth = patch.parsed("birthDate", LocalDate::parse);
        patch.parsed("gender", Gender::valueOf);

        assertThat(birth.isPresent()).isFalse();
        assertThat(violationsOf(patch)).extracting(Problem.Violation::message)
                .containsExactly("must be a string", "has an invalid value");
    }

    private static List<Problem.Violation> violationsOf(PatchBody patch) {
        try {
            patch.validate();
        } catch (InvalidRequestException e) {
            return e.violations();
        }
        throw new AssertionError("expected violations");
    }

    private static PatchBody patch(String raw) {
        return PatchBody.of(json(raw), CLEARABLE);
    }

    private static JsonNode json(String raw) {
        try {
            return JSON.readTree(raw);
        } catch (Exception e) {
            throw new IllegalArgumentException(e);
        }
    }
}
