package com.hoopsacademy.core.domain.shared;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PatchTest {

    @Test
    void absentKeepsPresentReplacesNullClears() {
        assertThat(Patch.<String>absent().applyTo("old")).isEqualTo("old");
        assertThat(Patch.of("new").applyTo("old")).isEqualTo("new");
        assertThat(Patch.<String>of(null).applyTo("old")).isNull();
        assertThat(Patch.absent().isPresent()).isFalse();
        assertThat(Patch.of(null).isPresent()).isTrue();
        assertThat(Patch.of(null).clears()).isTrue();
        assertThat(Patch.of("x").clears()).isFalse();
    }

    @Test
    void localeCodes() {
        assertThat(AppLocale.fromCode("id")).isEqualTo(AppLocale.ID);
        assertThat(AppLocale.ES.code()).isEqualTo("es");
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> AppLocale.fromCode("fr"))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
