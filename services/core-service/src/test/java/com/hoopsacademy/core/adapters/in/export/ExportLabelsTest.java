package com.hoopsacademy.core.adapters.in.export;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.audit.AuditActorKind;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditTargetType;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.shared.AppLocale;
import java.util.Arrays;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

/** ADR-0048: header and enum labels in es / en / id; every language has every key and every enum value. */
class ExportLabelsTest {

    @Test
    void everyLanguageHasExactlyTheEnglishKeys() {
        Set<String> english = ExportLabels.of(AppLocale.EN).keys();

        assertThat(english).isNotEmpty();
        for (AppLocale locale : AppLocale.values()) {
            assertThat(ExportLabels.of(locale).keys()).as(locale.code()).isEqualTo(english);
        }
    }

    @ParameterizedTest
    @EnumSource(AppLocale.class)
    void everyEnumValueHasALabel(AppLocale locale) {
        ExportLabels labels = ExportLabels.of(locale);

        Arrays.stream(AuditAction.values()).forEach(action -> assertThat(labels.action(action)).isNotBlank());
        Arrays.stream(AuditTargetType.values()).forEach(type -> assertThat(labels.target(type)).isNotBlank());
        Arrays.stream(AuditActorKind.values()).forEach(kind -> assertThat(labels.actor(kind)).isNotBlank());
        Arrays.stream(TenantRole.values()).forEach(role -> assertThat(labels.role(role)).isNotBlank());
        Arrays.stream(Gender.values()).forEach(gender -> assertThat(labels.gender(gender)).isNotBlank());
    }

    @Test
    void labelsAreTranslatedAndTakeArguments() {
        assertThat(ExportLabels.of(AppLocale.EN).role(TenantRole.ASSISTANT_COACH)).isEqualTo("Assistant coach");
        assertThat(ExportLabels.of(AppLocale.ES).role(TenantRole.ASSISTANT_COACH)).isEqualTo("Entrenador asistente");
        assertThat(ExportLabels.of(AppLocale.ID).role(TenantRole.ASSISTANT_COACH)).isEqualTo("Asisten pelatih");
        assertThat(ExportLabels.of(AppLocale.ES).actor(AuditActorKind.PLATFORM))
                .isEqualTo("Administrador de la plataforma");
        assertThat(ExportLabels.of(AppLocale.EN).text("roster.guardianEmail", 2)).isEqualTo("Guardian 2 e-mail");
        assertThat(ExportLabels.of(AppLocale.ID).gender(Gender.FEMALE)).isEqualTo("Perempuan");
    }

    @Test
    void aMissingNullValueHasNoLabel() {
        assertThat(ExportLabels.of(AppLocale.EN).gender(null)).isNull();
    }
}
