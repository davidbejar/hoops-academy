package com.hoopsacademy.core.domain.signup;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.shared.AppLocale;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class RequesterTest {

    @Test
    void keepsTheNormalisedNameTheTrimmedEmailTheRoleAndTheLocale() {
        Requester requester = Requester.of("  Ana   Ruiz ", " ana@example.com ", RequesterRole.COACH, AppLocale.ES);

        assertThat(requester.name()).contains("Ana Ruiz");
        assertThat(requester.email()).isEqualTo("ana@example.com");
        assertThat(requester.role()).isEqualTo(RequesterRole.COACH);
        assertThat(requester.locale()).isEqualTo(AppLocale.ES);
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "   "})
    void aBlankNameMeansNoName(String name) {
        assertThat(Requester.of(name, "a@example.com", RequesterRole.ADMIN, AppLocale.EN).name()).isEmpty();
    }

    @Test
    void anAbsentNameAndLocaleDefaultToNoNameAndEnglish() {
        Requester requester = Requester.of(null, "a@example.com", RequesterRole.PARENT, null);

        assertThat(requester.name()).isEqualTo(Optional.empty());
        assertThat(requester.locale()).isEqualTo(AppLocale.EN);
    }

    @Test
    void aNameOfAtMost120CharactersWithoutControlCharacters() {
        assertThat(Requester.of("n".repeat(120), "a@example.com", RequesterRole.ADMIN, AppLocale.EN).name())
                .contains("n".repeat(120));
        assertThatThrownBy(() -> Requester.of("n".repeat(121), "a@example.com", RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_NAME");
        assertThatThrownBy(() -> Requester.of("Ana\u0000", "a@example.com", RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_NAME");
        assertThat(Requester.of("Ana\r\nBcc: x", "a@example.com", RequesterRole.ADMIN, AppLocale.EN).name())
                .as("line breaks collapse to one space").contains("Ana Bcc: x");
    }

    @Test
    void anEmailOfAtMost254Characters() {
        String longest = "a".repeat(242) + "@example.com";
        assertThat(Requester.of(null, longest, RequesterRole.ADMIN, AppLocale.EN).email()).hasSize(254);
        assertThatThrownBy(() -> Requester.of(null, "a" + longest, RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_EMAIL");
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "plain", "@example.com", "ana@", "ana@@example.com", "a na@example.com",
            "ana@example.com\r\nBcc: victim@example.com", "ana\u0000@example.com"})
    void aMalformedEmailIsRejected(String email) {
        assertThatThrownBy(() -> Requester.of(null, email, RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_EMAIL");
    }

    @Test
    void anAbsentEmailOrRoleIsRejected() {
        assertThatThrownBy(() -> Requester.of(null, null, RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_EMAIL");
        assertThatThrownBy(() -> Requester.of(null, "a@example.com", null, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class).hasFieldOrPropertyWithValue("code", "INVALID_ROLE");
    }

    @Test
    void playersCannotRequestAnAcademy() {
        assertThat(RequesterRole.values()).extracting(Enum::name).containsExactly("ADMIN", "COACH", "PARENT");
    }

    @Test
    void theRecordConstructorAppliesTheSameRules() {
        assertThatThrownBy(() -> new Requester(Optional.empty(), "bad", RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Requester(null, "a@example.com", RequesterRole.ADMIN, AppLocale.EN))
                .isInstanceOf(NullPointerException.class);
    }
}
