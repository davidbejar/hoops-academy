package com.hoopsacademy.core.adapters.in.shared;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class MergePatchTest {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Test
    void distinguishesAbsentNullAndValues() throws Exception {
        MergePatch patch = MergePatch.of(json("{\"phone\":null,\"givenName\":\"Ana\",\"birthDate\":\"2010-02-28\"}"));
        Patch<String> phone = patch.text("phone", 32);
        Patch<String> email = patch.email("email", true);
        Patch<String> given = patch.requiredText("givenName", 80);
        Patch<LocalDate> birth = patch.parsed("birthDate", true, LocalDate::parse);
        patch.validate(true);
        assertThat(phone.clears()).isTrue();
        assertThat(email.isPresent()).isFalse();
        assertThat(given.applyTo("x")).isEqualTo("Ana");
        assertThat(birth.applyTo(null)).isEqualTo(LocalDate.of(2010, 2, 28));
    }

    @Test
    void collectsEveryViolation() throws Exception {
        MergePatch patch = MergePatch.of(json(
                "{\"givenName\":null,\"phone\":\"" + "9".repeat(33) + "\",\"email\":\"nope\",\"birthDate\":3,"
                        + "\"gender\":\"X\"}"));
        patch.requiredText("givenName", 80);
        patch.text("phone", 32);
        patch.email("email", false);
        patch.parsed("birthDate", true, LocalDate::parse);
        patch.parsed("gender", true, com.hoopsacademy.core.domain.membership.Gender::valueOf);
        assertThatThrownBy(() -> patch.validate(false)).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).extracting(v -> v.field())
                        .containsExactly("givenName", "phone", "email", "birthDate", "gender"));
    }

    @Test
    void propertiesOutsideTheAllowedSetAreViolations() throws Exception {
        MergePatch patch = MergePatch.of(json("{\"givenName\":\"Ana\",\"phone\":\"1\",\"roles\":[]}"));
        patch.requiredText("givenName", 80);
        patch.allowOnly("givenName", "familyName", "email");
        assertThatThrownBy(() -> patch.validate(true)).isInstanceOfSatisfying(InvalidRequestException.class,
                e -> assertThat(e.violations()).extracting(v -> v.field()).containsExactly("phone", "roles"));
    }

    @Test
    void emptyBodiesAndNonObjectsAreRejected() throws Exception {
        assertThatThrownBy(() -> MergePatch.of(json("{}")).validate(true)).isInstanceOf(InvalidRequestException.class);
        assertThatThrownBy(() -> MergePatch.of(json("[1]"))).isInstanceOf(InvalidRequestException.class);
        assertThatThrownBy(() -> MergePatch.of(null)).isInstanceOf(InvalidRequestException.class);
        MergePatch.of(json("{}")).validate(false);
    }

    @Test
    void domainRuleViolationsOfParsersPropagate() throws Exception {
        MergePatch patch = MergePatch.of(json("{\"timezone\":\"Mars/Olympus\"}"));
        assertThatThrownBy(() -> patch.parsed("timezone", false, Constraints::zone))
                .isInstanceOf(DomainRuleViolation.class);
        assertThat(Constraints.zone("Asia/Jakarta").getId()).isEqualTo("Asia/Jakarta");
        assertThat(InvalidRequestException.of("f", "m").violations()).hasSize(1);
    }

    private static JsonNode json(String raw) throws Exception {
        return JSON.readTree(raw);
    }
}
