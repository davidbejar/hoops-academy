package com.hoopsacademy.core.domain.shared;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import com.hoopsacademy.common.i18n.AppLanguage;
import org.junit.jupiter.api.Test;

/** core's UI locale is a language of the platform; Accept-Language is negotiated once in common-quarkus (X-07). */
class AppLocaleTest {

    @Test
    void everyLanguageOfThePlatformIsALocale() {
        for (AppLanguage language : AppLanguage.values()) {
            assertThat(AppLocale.of(language).code()).isEqualTo(language.code());
        }
    }

    @Test
    void aStoredCodeIsReadExactly() {
        assertThat(AppLocale.fromCode("id")).isEqualTo(AppLocale.ID);
        assertThatIllegalArgumentException().isThrownBy(() -> AppLocale.fromCode("fr"));
    }
}
