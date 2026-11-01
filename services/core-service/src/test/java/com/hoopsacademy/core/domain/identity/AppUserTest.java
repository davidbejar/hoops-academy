package com.hoopsacademy.core.domain.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.core.domain.shared.AppLocale;
import org.junit.jupiter.api.Test;

class AppUserTest {

    @Test
    void registeredLoginHasNoLocaleUntilChosen() {
        AppUser user = AppUser.register("sub-1", "a@example.com");
        assertThat(user.locale()).isNull();
        AppUser withLocale = user.withLocale(AppLocale.EN);
        assertThat(withLocale.locale()).isEqualTo(AppLocale.EN);
        assertThat(withLocale.id()).isEqualTo(user.id());
        assertThat(withLocale.subject()).isEqualTo("sub-1");
    }

    @Test
    void subjectAndIdAreRequired() {
        assertThatThrownBy(() -> AppUser.register(" ", null)).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> AppUser.register(null, null)).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new AppUser(null, "sub", null, null)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> new UserId(null)).isInstanceOf(NullPointerException.class);
    }
}
