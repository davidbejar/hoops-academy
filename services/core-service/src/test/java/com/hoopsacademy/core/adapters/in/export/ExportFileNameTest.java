package com.hoopsacademy.core.adapters.in.export;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;

/** ADR-0048: {@code hoops-<academy-slug>-<what>-<yyyyMMdd>.csv}, ASCII only. */
class ExportFileNameTest {

    private static final LocalDate DAY = LocalDate.of(2026, 11, 10);

    @Test
    void theNameJoinsTheAcademyWhatAndDay() {
        assertThat(ExportFileName.csv("hangtuah", DAY, "audit")).isEqualTo("hoops-hangtuah-audit-20261110.csv");
        assertThat(ExportFileName.csv("dewa-united", LocalDate.of(2027, 1, 2), "roster", "U12 Lions"))
                .isEqualTo("hoops-dewa-united-roster-u12-lions-20270102.csv");
    }

    @Test
    void eachPartIsReducedToLowerCaseAsciiWords() {
        assertThat(ExportFileName.csv("Baskonia", DAY, "roster", "Infantil Ñ – Niñas \"A\"/B"))
                .isEqualTo("hoops-baskonia-roster-infantil-n-ninas-a-b-20261110.csv");
        assertThat(ExportFileName.csv("x", DAY, "roster", "  --Élan__ 07  ")).isEqualTo("hoops-x-roster-elan-07-20261110.csv");
    }

    @Test
    void aPartWithoutAsciiLettersOrDigitsIsLeftOut() {
        assertThat(ExportFileName.csv("x", DAY, "roster", "猛虎")).isEqualTo("hoops-x-roster-20261110.csv");
        assertThat(ExportFileName.ascii("—")).isEmpty();
    }

    @Test
    void aLongPartIsCutAtFortyCharacters() {
        String part = ExportFileName.ascii("a".repeat(30) + " " + "b".repeat(30));

        assertThat(part).hasSize(40).doesNotEndWith("-").startsWith("a".repeat(30) + "-b");
        assertThat(ExportFileName.ascii("a".repeat(39) + " b")).isEqualTo("a".repeat(39));
    }

    @Test
    void theAttachmentHeaderQuotesTheName() {
        assertThat(ExportFileName.attachment("hoops-x-audit-20261110.csv"))
                .isEqualTo("attachment; filename=\"hoops-x-audit-20261110.csv\"");
    }
}
