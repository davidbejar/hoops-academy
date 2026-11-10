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
}
