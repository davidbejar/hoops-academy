package com.hoopsacademy.core.domain.export;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import org.junit.jupiter.api.Test;

/** ADR-0048: one file, no paging; more than 10,000 rows is refused with a Problem that asks for a narrower filter. */
class ExportLimitTest {

    @Test
    void upToTenThousandRowsAreExported() {
        assertThat(ExportLimit.MAX_ROWS).isEqualTo(10_000);
        assertThatCode(() -> ExportLimit.requireWithin(0)).doesNotThrowAnyException();
        assertThatCode(() -> ExportLimit.requireWithin(10_000)).doesNotThrowAnyException();
    }

    @Test
    void moreRowsAreRefusedWithACodeAndAHint() {
        assertThatThrownBy(() -> ExportLimit.requireWithin(10_001)).isInstanceOf(DomainRuleViolation.class)
                .hasMessageContaining("10001").hasMessageContaining("10000").hasMessageContaining("Narrow")
                .extracting("code").isEqualTo("EXPORT_TOO_LARGE");
    }

    /** WP116: the printed roster's sheet (pdf-service, pdf.yaml) holds 60 players, 20 staff and 4 guardians each. */
    @Test
    void aPrintableRosterFitsTheSheet() {
        assertThat(ExportLimit.SHEET_MAX_PLAYERS).isEqualTo(60);
        assertThat(ExportLimit.SHEET_MAX_STAFF).isEqualTo(20);
        assertThat(ExportLimit.SHEET_MAX_GUARDIANS).isEqualTo(4);
        assertThatCode(() -> ExportLimit.requirePrintable(60, 20, 4)).doesNotThrowAnyException();
        assertThatCode(() -> ExportLimit.requirePrintable(0, 0, 0)).doesNotThrowAnyException();
    }

    @Test
    void aLargerRosterIsRefusedNamingWhatDoesNotFit() {
        assertThatThrownBy(() -> ExportLimit.requirePrintable(61, 20, 4)).isInstanceOf(DomainRuleViolation.class)
                .hasMessageContaining("61 players").hasMessageContaining("at most 60").hasMessageContaining("CSV")
                .extracting("code").isEqualTo("EXPORT_TOO_LARGE");
        assertThatThrownBy(() -> ExportLimit.requirePrintable(60, 21, 4))
                .hasMessageContaining("21 staff").hasMessageContaining("at most 20");
        assertThatThrownBy(() -> ExportLimit.requirePrintable(60, 20, 5))
                .hasMessageContaining("5 guardians").hasMessageContaining("at most 4");
    }
}
